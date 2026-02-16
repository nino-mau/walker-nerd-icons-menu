#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

if [[ -n "${SUDO_USER:-}" ]]; then
  USER_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
else
  USER_HOME="$HOME"
fi

ELEPHANT_CONFIG="$USER_HOME/.config/elephant"
ELEPHANT_MENUS_CONFIG="$ELEPHANT_CONFIG/menus"
SOURCE_FILE="$SCRIPT_DIR/nerd-icons.lua"
TARGET_FILE="$ELEPHANT_MENUS_CONFIG/nerd-icons.lua"
WALKER_CONFIG="$USER_HOME/.config/walker/config.toml"

echo "=== Installing Elephant Nerd Icons ==="
echo "Version: $VERSION"
echo

if [[ ! -f "$SOURCE_FILE" ]]; then
  echo -e "${RED}Error: nerd-icons.lua not found in $SCRIPT_DIR${NC}"
  exit 1
fi

if [[ ! -d "$ELEPHANT_CONFIG" ]]; then
  echo -e "${RED}Error: Elephant config directory not found at $ELEPHANT_CONFIG${NC}"
  echo "Install and run Elephant once, then re-run this script."
  exit 1
fi

if ! command -v wl-copy >/dev/null 2>&1; then
  echo -e "${YELLOW}Warning: wl-copy not found. Install wl-clipboard for copy action.${NC}"
fi

if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
  echo -e "${YELLOW}Warning: neither curl nor wget found. Menu cannot fetch glyph data from network.${NC}"
fi

mkdir -p "$ELEPHANT_MENUS_CONFIG"
cp "$SOURCE_FILE" "$TARGET_FILE"

echo -e "${GREEN}✓ Installed menu:${NC} $TARGET_FILE"

if [[ -f "$WALKER_CONFIG" ]]; then
  echo
  echo "Add this prefix if you have not configured it yet:"
  echo
  echo '[[providers.prefixes]]'
  echo 'prefix = "nf"'
  echo 'provider = "menus:nerd-icons"'
else
  echo -e "${YELLOW}Warning: Walker config not found at $WALKER_CONFIG${NC}"
fi

echo
echo -e "${GREEN}Done.${NC} Restart Walker and Elephant."
