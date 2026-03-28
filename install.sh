#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Excalidraw Skill for Claude Code — One-Command Installer
# https://github.com/Minara-AI/excalidraw-skill
#
# Usage:
#   Remote:  curl -fsSL https://raw.githubusercontent.com/Minara-AI/excalidraw-skill/main/install.sh | bash
#   Local:   bash install.sh [target-project-dir]
# ============================================================

REPO_URL="https://github.com/Minara-AI/excalidraw-skill.git"
PROJECT_DIR="${1:-.}"

# Resolve to absolute path
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

echo ""
echo "  Excalidraw Skill Installer"
echo "  Target: $PROJECT_DIR"
echo "  ─────────────────────────────"
echo ""

# --- Determine source directory ---
# If running from a local clone, use it; otherwise clone to temp dir
SCRIPT_DIR=""
TEMP_DIR=""

if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  CANDIDATE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [ -f "$CANDIDATE/skill/SKILL.md" ] && [ -f "$CANDIDATE/scripts/render.mjs" ]; then
    SCRIPT_DIR="$CANDIDATE"
  fi
fi

if [ -z "$SCRIPT_DIR" ]; then
  echo "  [*] Downloading from GitHub..."
  TEMP_DIR="$(mktemp -d)"
  git clone --depth 1 "$REPO_URL" "$TEMP_DIR" 2>/dev/null
  SCRIPT_DIR="$TEMP_DIR"
  echo "  [*] Download complete"
  echo ""
fi

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
    # Try downloading from GitHub LFS
    if [ -n "$TEMP_DIR" ]; then
      echo "  [*] Attempting to fetch font via git lfs pull..."
      (cd "$TEMP_DIR" && git lfs pull 2>/dev/null) || true
    fi
    if [ ! -f "$SRC" ]; then
      echo "  [!] Could not obtain $font. Please run: cd $SCRIPT_DIR && git lfs pull"
      exit 1
    fi
  fi
  FILE_SIZE=$(wc -c < "$SRC" | tr -d ' ')
  if [ "$FILE_SIZE" -lt 1000 ]; then
    echo "  [!] Font file $font appears to be a Git LFS pointer (${FILE_SIZE} bytes)"
    if [ -n "$TEMP_DIR" ]; then
      echo "  [*] Fetching real font via git lfs pull..."
      (cd "$TEMP_DIR" && git lfs install --local 2>/dev/null && git lfs pull 2>/dev/null) || true
      FILE_SIZE=$(wc -c < "$SRC" | tr -d ' ')
    fi
    if [ "$FILE_SIZE" -lt 1000 ]; then
      echo "  [!] Could not resolve LFS pointer for $font."
      echo "      Please install git-lfs and run: cd $SCRIPT_DIR && git lfs pull"
      exit 1
    fi
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

# --- Cleanup temp dir ---
if [ -n "$TEMP_DIR" ]; then
  rm -rf "$TEMP_DIR"
fi

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
# Only prompt if running interactively (not piped)
if [ -t 0 ]; then
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
fi

echo ""
echo "  Done! Happy diagramming."
echo ""
