#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Excalidraw Skill for Claude Code — One-Command Installer
# https://github.com/Minara-AI/excalidraw-skill
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${1:-.}"

# Resolve to absolute path
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

echo ""
echo "  Excalidraw Skill Installer"
echo "  Target: $PROJECT_DIR"
echo "  ─────────────────────────────"
echo ""

# --- Step 1: Copy SKILL.md ---
SKILL_DEST="$PROJECT_DIR/.claude/skills/excalidraw"
mkdir -p "$SKILL_DEST"
cp "$SCRIPT_DIR/skill/SKILL.md" "$SKILL_DEST/SKILL.md"
echo "  [1/5] Skill definition     → .claude/skills/excalidraw/SKILL.md"

# --- Step 2: Copy renderer + fonts ---
SCRIPTS_DEST="$PROJECT_DIR/scripts/excalidraw"
mkdir -p "$SCRIPTS_DEST"
cp "$SCRIPT_DIR/scripts/render.mjs" "$SCRIPTS_DEST/"

# Check if font files are real (not LFS pointers)
for font in Virgil.ttf Excalifont.ttf; do
  SRC="$SCRIPT_DIR/scripts/$font"
  if [ ! -f "$SRC" ]; then
    echo "  [!] Font file missing: $font"
    echo "      If you cloned with Git LFS, run: git lfs pull"
    exit 1
  fi
  FILE_SIZE=$(wc -c < "$SRC" | tr -d ' ')
  if [ "$FILE_SIZE" -lt 1000 ]; then
    echo "  [!] Font file $font appears to be a Git LFS pointer (${FILE_SIZE} bytes)"
    echo "      Run: cd $SCRIPT_DIR && git lfs pull"
    exit 1
  fi
  cp "$SRC" "$SCRIPTS_DEST/"
done
echo "  [2/5] Renderer + fonts     → scripts/excalidraw/"

# --- Step 3: Install Playwright if needed ---
cd "$PROJECT_DIR"
if node -e "require('@playwright/test')" 2>/dev/null; then
  echo "  [3/5] @playwright/test     ✓ already installed"
else
  echo "  [3/5] Installing @playwright/test..."
  if [ -f "pnpm-lock.yaml" ]; then
    pnpm add -D @playwright/test
  elif [ -f "yarn.lock" ]; then
    yarn add -D @playwright/test
  elif [ -f "package.json" ]; then
    npm install -D @playwright/test
  else
    npm init -y > /dev/null 2>&1
    npm install -D @playwright/test
  fi
  echo "  [3/5] @playwright/test     ✓ installed"
fi

# --- Step 4: Install Chromium if needed ---
CHROMIUM_CHECK=$(npx playwright install --dry-run chromium 2>&1 || true)
if echo "$CHROMIUM_CHECK" | grep -qi "already installed\|up to date"; then
  echo "  [4/5] Chromium             ✓ already installed"
else
  echo "  [4/5] Installing Chromium (this may take a minute)..."
  npx playwright install chromium
  echo "  [4/5] Chromium             ✓ installed"
fi

# --- Step 5: Create default output directory ---
mkdir -p "$PROJECT_DIR/diagrams"
echo "  [5/5] Output directory     → diagrams/"

# --- Done ---
echo ""
echo "  ─────────────────────────────"
echo "  Installation complete!"
echo ""
echo "  Usage:"
echo "    In Claude Code, just ask:"
echo "    \"Draw an architecture diagram showing Client → API → Database\""
echo ""
echo "    Or render manually:"
echo "    node scripts/excalidraw/render.mjs input.excalidraw output.png"
echo ""

# --- Optional: oh-my-claudecode ---
echo "  ─────────────────────────────"
echo "  Optional Enhancement: oh-my-claudecode (OMC)"
echo ""
echo "  oh-my-claudecode is a multi-agent orchestration layer for Claude Code."
echo "  With OMC installed, the Excalidraw skill gains:"
echo ""
echo "    • architect agent  — designs visual style before you draw"
echo "    • critic agent     — challenges the design to avoid clichés"
echo "    • designer agent   — reviews rendered images for layout/proportion issues"
echo ""
echo "  Without OMC, Claude handles all these steps directly (still works, just"
echo "  less specialized). The skill is fully functional either way."
echo ""
echo "  GitHub: https://github.com/anthropics/claude-code-omc"
echo ""

read -r -p "  Install oh-my-claudecode? [y/N] " INSTALL_OMC
case "$INSTALL_OMC" in
  [yY][eE][sS]|[yY])
    echo ""
    echo "  Installing oh-my-claudecode..."
    if command -v npx &> /dev/null; then
      npx oh-my-claudecode setup 2>/dev/null || {
        echo "  [!] Auto-install failed. Please install manually:"
        echo "      Visit: https://github.com/anthropics/claude-code-omc"
        echo "      Or run: npx oh-my-claudecode setup"
      }
    else
      echo "  [!] npx not found. Please install manually:"
      echo "      Visit: https://github.com/anthropics/claude-code-omc"
    fi
    ;;
  *)
    echo ""
    echo "  Skipped. You can install OMC later:"
    echo "  https://github.com/anthropics/claude-code-omc"
    ;;
esac

echo ""
echo "  Done! Happy diagramming."
echo ""
