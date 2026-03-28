#!/usr/bin/env node

/**
 * Excalidraw Headless Renderer (Playwright + Excalidraw CDN)
 *
 * Usage:
 *   node scripts/excalidraw/render.mjs <scene.excalidraw> [output.png|output.svg] [--width=1600] [--height=900] [--scale=2] [--theme=light|dark]
 *
 * Examples:
 *   node scripts/excalidraw/render.mjs diagram.excalidraw diagram.png
 *   node scripts/excalidraw/render.mjs diagram.excalidraw diagram.svg --theme=dark
 *   node scripts/excalidraw/render.mjs diagram.excalidraw diagram.png --width=1200 --height=675 --scale=2
 */

import { chromium } from '@playwright/test';
import { readFileSync, writeFileSync } from 'fs';
import { resolve, dirname, extname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

function parseArgs(args) {
  const positional = [];
  const flags = {};
  for (const arg of args) {
    if (arg.startsWith('--')) {
      const [key, val] = arg.slice(2).split('=');
      flags[key] = val ?? 'true';
    } else {
      positional.push(arg);
    }
  }
  return { positional, flags };
}

async function render() {
  const { positional, flags } = parseArgs(process.argv.slice(2));

  const inputFile = positional[0];
  if (!inputFile) {
    console.error('Usage: node render.mjs <scene.excalidraw> [output.png|svg] [--width=1600] [--height=900] [--scale=2] [--theme=light|dark]');
    process.exit(1);
  }

  const outputFile = positional[1] || inputFile.replace(/\.excalidraw$/, '.png');
  const width = parseInt(flags.width || '1600', 10);
  const height = parseInt(flags.height || '900', 10);
  const scale = parseInt(flags.scale || '2', 10);
  const theme = flags.theme || 'light';
  const format = extname(outputFile).slice(1);

  const sceneJSON = readFileSync(resolve(inputFile), 'utf-8');
  const sceneData = JSON.parse(sceneJSON);

  if (!sceneData.appState) sceneData.appState = {};
  sceneData.appState.theme = theme;
  if (theme === 'dark' && !sceneData.appState.viewBackgroundColor) {
    sceneData.appState.viewBackgroundColor = '#1e1e1e';
  }

  console.log(`Rendering ${inputFile} → ${outputFile} (${width}x${height} @${scale}x, ${theme}, ${format})`);

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width, height },
    deviceScaleFactor: scale,
  });
  const page = await context.newPage();

  // Collect console messages for debugging
  const logs = [];
  page.on('console', (msg) => logs.push(`[${msg.type()}] ${msg.text()}`));
  page.on('pageerror', (err) => logs.push(`[pageerror] ${err.message}`));

  try {
    // Navigate to blank page first
    await page.goto('about:blank');

    // Load React + ReactDOM first (Excalidraw depends on them)
    await page.addScriptTag({
      url: 'https://unpkg.com/react@18.3.1/umd/react.production.min.js',
    });
    await page.addScriptTag({
      url: 'https://unpkg.com/react-dom@18.3.1/umd/react-dom.production.min.js',
    });

    // Load Excalidraw UMD bundle
    await page.addScriptTag({
      url: 'https://unpkg.com/@excalidraw/excalidraw@0.17.6/dist/excalidraw.production.min.js',
    });

    // Wait for ExcalidrawLib to be available
    await page.waitForFunction(() => typeof window.ExcalidrawLib !== 'undefined', {
      timeout: 20000,
    });

    console.log('ExcalidrawLib loaded');

    // Load Excalidraw fonts from local files (avoids CORS issues)
    const virgilB64 = readFileSync(resolve(__dirname, 'Virgil.ttf')).toString('base64');
    const excalifontB64 = readFileSync(resolve(__dirname, 'Excalifont.ttf')).toString('base64');

    await page.evaluate(async ({ virgilB64, excalifontB64 }) => {
      const fontConfigs = [
        { name: 'Virgil', data: virgilB64 },
        { name: 'Excalifont', data: excalifontB64 },
      ];

      for (const { name, data } of fontConfigs) {
        try {
          const font = new FontFace(name, `url(data:font/ttf;base64,${data})`);
          const loaded = await font.load();
          document.fonts.add(loaded);
          console.log(`Font loaded: ${name}`);
        } catch (e) {
          console.warn(`Failed to load font ${name}:`, e.message);
        }
      }

      await document.fonts.ready;
      console.log('All fonts ready, count:', document.fonts.size);
    }, { virgilB64, excalifontB64 });

    console.log('Fonts loaded');

    // Run the export
    const result = await page.evaluate(async ({ sceneData, scale, format }) => {
      const elements = sceneData.elements || [];
      const appState = {
        exportBackground: true,
        viewBackgroundColor: sceneData.appState?.viewBackgroundColor || '#ffffff',
        theme: sceneData.appState?.theme || 'light',
      };

      const output = {};

      try {
        // Try SVG export
        if (window.ExcalidrawLib.exportToSvg) {
          const svg = await window.ExcalidrawLib.exportToSvg({
            elements,
            appState,
            files: sceneData.files || null,
          });
          output.svg = svg.outerHTML;
        }

        // Try Canvas/PNG export
        if (format === 'png' && window.ExcalidrawLib.exportToCanvas) {
          const canvas = await window.ExcalidrawLib.exportToCanvas({
            elements,
            appState,
            files: sceneData.files || null,
            getDimensions: (w, h) => ({ width: w * scale, height: h * scale, scale }),
          });
          output.png = canvas.toDataURL('image/png').split(',')[1];
        }
      } catch (err) {
        output.error = err.message + '\n' + err.stack;
      }

      return output;
    }, { sceneData, scale, format });

    if (result.error) {
      throw new Error(`Excalidraw export error: ${result.error}`);
    }

    if (format === 'svg') {
      if (!result.svg) throw new Error('SVG export returned null');
      writeFileSync(resolve(outputFile), result.svg, 'utf-8');
    } else {
      // Prefer PNG from canvas, fallback to converting SVG
      if (result.png) {
        writeFileSync(resolve(outputFile), Buffer.from(result.png, 'base64'));
      } else if (result.svg) {
        // Fallback: save SVG instead
        const svgPath = outputFile.replace(/\.png$/, '.svg');
        writeFileSync(resolve(svgPath), result.svg, 'utf-8');
        console.log(`PNG export unavailable, saved SVG to ${svgPath}`);
      } else {
        throw new Error('Both PNG and SVG exports returned null');
      }
    }

    console.log(`Done! Saved to ${outputFile}`);
  } catch (err) {
    console.error('Render failed:', err.message);
    if (logs.length > 0) {
      console.error('Browser logs:');
      logs.forEach((l) => console.error('  ', l));
    }

    const debugPath = resolve(outputFile.replace(/\.\w+$/, '.debug.png'));
    await page.screenshot({ path: debugPath, fullPage: true });
    console.error(`Debug screenshot saved to ${debugPath}`);
    process.exit(1);
  } finally {
    await browser.close();
  }
}

render();
