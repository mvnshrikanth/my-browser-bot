#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"

DEFAULT_MODEL="claude-sonnet-4-6"
DEFAULT_APP_URL="https://nexus-finance-6c6c6.web.app/"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${BLUE}=== Browser Bot Setup ===${NC}"
echo ""

# ── 1. Python check ──────────────────────────────────────────────────────────
if ! command -v python3 &>/dev/null; then
    echo -e "${RED}Error: python3 not found. Please install Python 3.8+.${NC}"
    exit 1
fi
PYTHON_VER=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
echo -e "${GREEN}✓ Python $PYTHON_VER${NC}"

# ── 2. Virtual environment ────────────────────────────────────────────────────
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
fi
# shellcheck source=/dev/null
source "$VENV_DIR/bin/activate"
echo -e "${GREEN}✓ Virtual environment active${NC}"

# ── 3. Dependencies ───────────────────────────────────────────────────────────
echo "Installing dependencies..."
pip install -q -r "$SCRIPT_DIR/requirements.txt"
echo -e "${GREEN}✓ Dependencies installed${NC}"

# ── 4. Playwright browsers ────────────────────────────────────────────────────
echo "Checking Playwright browsers..."
python3 -m playwright install chromium --quiet 2>/dev/null || true
echo -e "${GREEN}✓ Playwright browsers ready${NC}"
echo ""

# ── 5. API key ────────────────────────────────────────────────────────────────
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo -e "${YELLOW}ANTHROPIC_API_KEY is not set.${NC}"
    read -rp "Enter your Anthropic API key: " ANTHROPIC_API_KEY
    echo ""
    export ANTHROPIC_API_KEY
fi
echo -e "${GREEN}✓ API key configured${NC}"
echo ""

# ── 6. Show current config and prompt for changes ─────────────────────────────
CURRENT_MODEL="${MODEL:-$DEFAULT_MODEL}"
CURRENT_APP_URL="${APP_URL:-$DEFAULT_APP_URL}"

echo -e "${BOLD}Current configuration:${NC}"
echo -e "  Model   : ${BLUE}$CURRENT_MODEL${NC}"
echo -e "  App URL : ${BLUE}$CURRENT_APP_URL${NC}"
echo ""

read -rp "Continue with this setup? [Y/n] " REPLY
REPLY="${REPLY:-Y}"
echo ""

if [[ "$REPLY" =~ ^[Nn]$ ]]; then
    read -rp "Model   [$CURRENT_MODEL]: " NEW_MODEL
    MODEL="${NEW_MODEL:-$CURRENT_MODEL}"

    read -rp "App URL [$CURRENT_APP_URL]: " NEW_URL
    APP_URL="${NEW_URL:-$CURRENT_APP_URL}"

    echo ""
    echo -e "${BOLD}Running with:${NC}"
    echo -e "  Model   : ${BLUE}$MODEL${NC}"
    echo -e "  App URL : ${BLUE}$APP_URL${NC}"
    echo ""
else
    MODEL="$CURRENT_MODEL"
    APP_URL="$CURRENT_APP_URL"
fi

export MODEL
export APP_URL

# ── 7. Run ────────────────────────────────────────────────────────────────────
echo -e "${BOLD}${BLUE}Starting agent...${NC}"
echo ""
python3 "$SCRIPT_DIR/test_ai.py"
