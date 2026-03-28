# Excalidraw Skill for Claude Code

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude_Code-Skill-blueviolet?logo=anthropic&logoColor=white)](https://claude.ai/claude-code)
[![Excalidraw](https://img.shields.io/badge/Excalidraw-0.17.6-6965db?logo=excalidraw&logoColor=white)](https://excalidraw.com)
[![Playwright](https://img.shields.io/badge/Playwright-%3E%3D1.40-45ba4b?logo=playwright&logoColor=white)](https://playwright.dev)
[![Node.js](https://img.shields.io/badge/Node.js-%3E%3D18-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux-lightgrey)]()
[![oh-my-claudecode](https://img.shields.io/badge/OMC-Optional-orange)](https://github.com/anthropics/claude-code-omc)

[中文文档](README.zh-CN.md)

**Generate hand-drawn diagrams from natural language in Claude Code.**

Describe what you want → get a polished Excalidraw PNG/SVG with hand-drawn Virgil font, hachure fills, and monochrome-first aesthetics.

![Example: cover](examples/cover.png)

<details>
<summary>More examples</summary>

![Example: architecture diagram](examples/three-layers.png)
![Example: workflow](examples/workflow.png)

</details>

### Tech Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Skill Engine** | [Claude Code](https://claude.ai/claude-code) | AI generates Excalidraw scene JSON from natural language |
| **Renderer** | [Playwright](https://playwright.dev) + Headless Chromium | Loads Excalidraw in browser, exports PNG/SVG |
| **Drawing Library** | [Excalidraw](https://excalidraw.com) 0.17.6 (via CDN) | Hand-drawn rendering engine |
| **Fonts** | Virgil + Excalifont (bundled) | Hand-written style typefaces |
| **Agent Orchestration** | [oh-my-claudecode](https://github.com/anthropics/claude-code-omc) (optional) | Multi-agent design/review pipeline |

### Requirements

| Requirement | Version | Note |
|-------------|---------|------|
| Node.js | >= 18 | Runtime |
| Claude Code | Latest | CLI, desktop, or IDE extension |
| OS | macOS / Linux | Windows via WSL |
| Disk space | ~25MB | Font files |

---

## Quick Start

### Option 1: One-command install (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/Minara-AI/excalidraw-skill/main/install.sh | bash
```

That's it — no need to clone the repo. The installer downloads everything automatically.

### Option 2: Let Claude install it for you

Just tell Claude Code in conversation:

```
Help me install the Excalidraw skill from https://github.com/Minara-AI/excalidraw-skill
```

Claude will run the installer and set everything up automatically.

### Option 3: Install from local clone

```bash
git clone git@github.com:Minara-AI/excalidraw-skill.git
cd your-project
bash /path/to/excalidraw-skill/install.sh
```

Then in Claude Code, use the `/excalidraw` slash command:

```
/excalidraw Draw an architecture diagram showing Client → API Gateway → Database
```

Or just describe what you want in natural language — Claude will automatically detect diagram requests:

```
"Help me draw a flowchart for the CI/CD pipeline"
```

That's it. Claude will design the visual style, generate `.excalidraw` JSON, render it to PNG, review the output, and iterate until it looks good.

---

## How It Works

```
Step 0: Design Phase     — Determine visual style (metaphor, layout, colors)
Step 1: Generate JSON    — Claude writes Excalidraw scene JSON
Step 2: Render           — Playwright loads Excalidraw in headless Chromium → PNG/SVG
Step 3: Review           — Score the image on 6 dimensions, fix issues
Step 4: Iterate          — Re-render until all scores ≥ 7/10 (max 3 rounds)
```

### With oh-my-claudecode (Optional)

[oh-my-claudecode](https://github.com/anthropics/claude-code-omc) is a multi-agent orchestration layer for Claude Code. With OMC installed, the skill delegates specialized work to dedicated agents:

| Agent | Role |
|-------|------|
| `architect` | Designs visual style before drawing |
| `critic` | Challenges the style brief to avoid clichés |
| `designer` | Reviews rendered images for layout/proportion issues |

**Without OMC**, Claude handles all phases directly using built-in prompt templates. The skill is fully functional either way.

The installer will ask if you want to install OMC during setup.

---

## Examples

### Architecture Diagram

```
"Draw a 3-layer architecture: Model → Service → UI"
```

![Architecture diagram](examples/three-layers.png)

### Workflow

```
"Draw a pipeline: Describe requirement → Claude Code → Auto-generate → Review → Merge"
```

![Workflow diagram](examples/workflow.png)

---

## Render Options

```bash
node scripts/excalidraw/render.mjs <input.excalidraw> <output.png|svg> [options]
```

| Option | Default | Description |
|--------|---------|-------------|
| `--width` | `1600` | Canvas width |
| `--height` | `900` | Canvas height |
| `--scale` | `2` | HiDPI scale factor |
| `--theme` | `light` | `light` or `dark` |

**Common sizes:**

```bash
# Twitter 16:9 (default)
node scripts/excalidraw/render.mjs diagram.excalidraw diagram.png

# Square for Instagram
node scripts/excalidraw/render.mjs diagram.excalidraw diagram.png --width=1200 --height=1200

# Blog header
node scripts/excalidraw/render.mjs diagram.excalidraw diagram.png --width=1920 --height=1080

# SVG output
node scripts/excalidraw/render.mjs diagram.excalidraw diagram.svg
```

---

## Configuration

### Output Directory

Default: `diagrams/`. To change, either:

1. Tell Claude in conversation: *"Save diagrams to `docs/images/`"*
2. Or set it in your project's `CLAUDE.md`:

```markdown
## Diagrams
Save all generated diagrams to `docs/images/`
```

### Design Defaults

The skill uses a **monochrome-first** color philosophy:

- All strokes: black (`#1e1e1e`)
- Backgrounds: transparent or light gray (`#f5f5f5`)
- Max 1 accent color: purple (`#6741d9`) for emphasis
- Fill style: `hachure` (hand-drawn hatching)
- Roughness: `2` (very hand-drawn)

---

## Troubleshooting

### Playwright install fails

```bash
# Linux: install system dependencies
npx playwright install chromium --with-deps

# macOS: usually works without extra deps
npx playwright install chromium
```

### Fonts not rendering (text looks like system font)

Ensure font files in `scripts/excalidraw/` are real files, not Git LFS pointers:

```bash
# Check file sizes (should be >1MB)
ls -la scripts/excalidraw/*.ttf

# If they're tiny (<1KB), pull from LFS
git lfs pull
```

### Render produces blank image

Common causes:

1. **Elements outside viewport** — Ensure coordinates are within 0-1600 (x) and 0-900 (y)
2. **Missing `boundElements`** — Container shapes need `boundElements` referencing their text
3. **Invalid `containerId`** — Text `containerId` must match an existing element's `id`
4. **CDN timeout** — The renderer loads Excalidraw from unpkg.com. Check your network connection.

### Render takes too long

First render may be slow (~10s) as Chromium loads CDN scripts. Subsequent renders are faster (~5s).

---

## Requirements

- **Claude Code** (CLI, desktop app, or IDE extension)
- **Node.js** >= 18
- **macOS** or **Linux** (Windows via WSL)
- ~25MB disk space for font files

---

## How the Renderer Works

The renderer (`scripts/render.mjs`) is a self-contained Node.js script that:

1. Launches headless Chromium via Playwright
2. Loads React + Excalidraw from unpkg CDN
3. Injects Virgil/Excalifont fonts as base64 (avoids CORS)
4. Calls `ExcalidrawLib.exportToCanvas()` / `exportToSvg()`
5. Saves the result as PNG or SVG

No npm dependencies beyond `@playwright/test`. All rendering happens in the browser context.

---

## Project Structure

```
excalidraw-skill/
├── README.md              # English documentation
├── README.zh-CN.md        # 中文文档
├── LICENSE                # MIT
├── install.sh             # One-command installer
├── skill/
│   └── SKILL.md           # Claude Code skill definition
├── scripts/
│   ├── render.mjs         # Headless renderer
│   ├── Virgil.ttf         # Hand-drawn font (1.8MB)
│   └── Excalifont.ttf     # Excalidraw font (23MB)
└── examples/
    ├── three-layers.excalidraw
    ├── three-layers.png
    ├── workflow.excalidraw
    └── workflow.png
```

---

## License

MIT - see [LICENSE](LICENSE)

---

Built by [Minara AI](https://github.com/Minara-AI)
