# Excalidraw Skill for Claude Code

**Generate hand-drawn diagrams from natural language in Claude Code.**

Describe what you want → get a polished Excalidraw PNG/SVG with hand-drawn Virgil font, hachure fills, and monochrome-first aesthetics.

**用自然语言在 Claude Code 中生成手绘风格图表。**

描述你想要的内容 → 自动生成带有手写字体、斜线填充、黑白极简风格的 Excalidraw PNG/SVG。

![Example: architecture diagram](examples/three-layers.png)
![Example: workflow](examples/workflow.png)

---

## Quick Start / 快速开始

```bash
git clone git@github.com:Minara-AI/excalidraw-skill.git
cd your-project
bash /path/to/excalidraw-skill/install.sh
```

Then in Claude Code / 然后在 Claude Code 中:

```
"Draw an architecture diagram showing Client → API Gateway → Database"
```

That's it. Claude will generate the `.excalidraw` JSON, render it to PNG, review it, and iterate.

就这么简单。Claude 会自动生成 `.excalidraw` JSON、渲染成 PNG、审查并迭代优化。

---

## How It Works / 工作原理

```
Step 0: Design Phase     — Determine visual style (metaphor, layout, colors)
Step 1: Generate JSON    — Claude writes Excalidraw scene JSON
Step 2: Render           — Playwright loads Excalidraw in headless Chromium → PNG/SVG
Step 3: Review           — Score the image on 6 dimensions, fix issues
Step 4: Iterate          — Re-render until all scores ≥ 7/10 (max 3 rounds)
```

```
第 0 步：设计阶段     — 确定视觉风格（隐喻、布局、配色）
第 1 步：生成 JSON    — Claude 编写 Excalidraw 场景 JSON
第 2 步：渲染         — Playwright 在无头 Chromium 中加载 Excalidraw → PNG/SVG
第 3 步：审查         — 从 6 个维度评分，修复问题
第 4 步：迭代         — 重新渲染直到所有评分 ≥ 7/10（最多 3 轮）
```

### With oh-my-claudecode (Optional) / 配合 OMC（可选）

[oh-my-claudecode](https://github.com/anthropics/claude-code-omc) is a multi-agent orchestration layer for Claude Code. With OMC installed, the skill delegates specialized work to dedicated agents:

[oh-my-claudecode](https://github.com/anthropics/claude-code-omc) 是 Claude Code 的多 agent 编排层。安装后，skill 会将专业工作委派给专门的 agent：

| Agent | Role | 角色 |
|-------|------|------|
| `architect` | Designs visual style before drawing | 绘图前设计视觉风格 |
| `critic` | Challenges the style brief to avoid clichés | 对抗审查设计方案，避免陈词滥调 |
| `designer` | Reviews rendered images for layout/proportion issues | 审查渲染图片的布局和比例问题 |

**Without OMC**, Claude handles all phases directly using built-in prompt templates. The skill is fully functional either way.

**不使用 OMC 时**，Claude 使用内置的 prompt 模板直接处理所有阶段。无论是否安装 OMC，skill 都完全可用。

The installer will ask if you want to install OMC during setup.

安装脚本会在安装过程中询问是否安装 OMC。

---

## Examples / 示例

### Architecture Diagram / 架构图

```
"Draw a 3-layer architecture: Model → Service → UI"
```

![Architecture diagram](examples/three-layers.png)

### Workflow / 流程图

```
"Draw a pipeline: Describe requirement → Claude Code → Auto-generate → Review → Merge"
```

![Workflow diagram](examples/workflow.png)

---

## Render Options / 渲染选项

```bash
node scripts/excalidraw/render.mjs <input.excalidraw> <output.png|svg> [options]
```

| Option | Default | Description / 描述 |
|--------|---------|-------------------|
| `--width` | `1600` | Canvas width / 画布宽度 |
| `--height` | `900` | Canvas height / 画布高度 |
| `--scale` | `2` | HiDPI scale factor / 高分屏缩放 |
| `--theme` | `light` | `light` or `dark` / 浅色或深色主题 |

**Common sizes / 常用尺寸:**

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

## Configuration / 配置

### Output Directory / 输出目录

Default: `diagrams/`. To change, either:

默认：`diagrams/`。修改方式：

1. Tell Claude in conversation: *"Save diagrams to `docs/images/`"*
2. Or set it in your project's `CLAUDE.md`:

```markdown
## Diagrams
Save all generated diagrams to `docs/images/`
```

### Design Defaults / 设计默认值

The skill uses a **monochrome-first** color philosophy:

Skill 使用**黑白优先**的配色理念：

- All strokes: black (`#1e1e1e`)
- Backgrounds: transparent or light gray (`#f5f5f5`)
- Max 1 accent color: purple (`#6741d9`) for emphasis
- Fill style: `hachure` (hand-drawn hatching)
- Roughness: `2` (very hand-drawn)

---

## Troubleshooting / 常见问题

### Playwright install fails / Playwright 安装失败

```bash
# Linux: install system dependencies
npx playwright install chromium --with-deps

# macOS: usually works without extra deps
npx playwright install chromium
```

### Fonts not rendering (text looks like system font) / 字体未渲染（文字看起来像系统字体）

Ensure font files in `scripts/excalidraw/` are real files, not Git LFS pointers:

确保 `scripts/excalidraw/` 中的字体文件是真实文件，不是 Git LFS 指针：

```bash
# Check file sizes (should be >1MB)
ls -la scripts/excalidraw/*.ttf

# If they're tiny (<1KB), pull from LFS
git lfs pull
```

### Render produces blank image / 渲染出空白图片

Common causes / 常见原因:

1. **Elements outside viewport** — Ensure coordinates are within 0-1600 (x) and 0-900 (y)
2. **Missing `boundElements`** — Container shapes need `boundElements` referencing their text
3. **Invalid `containerId`** — Text `containerId` must match an existing element's `id`
4. **CDN timeout** — The renderer loads Excalidraw from unpkg.com. Check your network connection.

### Render takes too long / 渲染时间过长

First render may be slow (~10s) as Chromium loads CDN scripts. Subsequent renders are faster (~5s).

首次渲染可能较慢（~10秒），因为需要加载 CDN 脚本。后续渲染更快（~5秒）。

---

## Requirements / 系统要求

- **Claude Code** (CLI, desktop app, or IDE extension)
- **Node.js** >= 18
- **macOS** or **Linux** (Windows via WSL)
- ~25MB disk space for font files

---

## How the Renderer Works / 渲染器工作原理

The renderer (`scripts/excalidraw/render.mjs`) is a self-contained Node.js script that:

渲染器是一个自包含的 Node.js 脚本：

1. Launches headless Chromium via Playwright
2. Loads React + Excalidraw from unpkg CDN
3. Injects Virgil/Excalifont fonts as base64 (avoids CORS)
4. Calls `ExcalidrawLib.exportToCanvas()` / `exportToSvg()`
5. Saves the result as PNG or SVG

No npm dependencies beyond `@playwright/test`. All rendering happens in the browser context.

除 `@playwright/test` 外无其他 npm 依赖。所有渲染都在浏览器上下文中完成。

---

## Project Structure / 项目结构

```
excalidraw-skill/
├── README.md              # This file / 本文件
├── LICENSE                # MIT
├── install.sh             # One-command installer / 一键安装脚本
├── skill/
│   └── SKILL.md           # Claude Code skill definition / 技能定义
├── scripts/
│   ├── render.mjs         # Headless renderer / 无头渲染器
│   ├── Virgil.ttf         # Hand-drawn font (1.8MB) / 手写字体
│   └── Excalifont.ttf     # Excalidraw font (23MB) / Excalidraw 字体
└── examples/
    ├── three-layers.excalidraw
    ├── three-layers.png
    ├── workflow.excalidraw
    └── workflow.png
```

---

## License / 许可证

MIT - see [LICENSE](LICENSE)

---

Built by [Minara AI](https://github.com/Minara-AI)
