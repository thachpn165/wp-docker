#!/bin/bash

# === Auto-detect PROJECT_DIR (source code root) ===
if [[ -z "$PROJECT_DIR" ]]; then
  SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
  while [[ "$SCRIPT_PATH" != "/" ]]; do
    if [[ -f "$SCRIPT_PATH/shared/config/config.sh" ]]; then
      PROJECT_DIR="$SCRIPT_PATH"
      break
    fi
    SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
  done
fi

# === ✅ Load config.sh from PROJECT_DIR ===
CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi
source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/website_loader.sh"

echo -e "${BLUE}===== CREATE NEW WORDPRESS WEBSITE =====${NC}"

# Lấy domain từ người dùng
read -p "Enter domain (e.g. abc.com): " domain

php_choose_version || exit 1
php_version="$REPLY"

echo ""
read -p "🔐 Auto-generate random admin account? [Y/n]: " choice
choice="${choice:-Y}"
choice="$(echo "$choice" | tr '[:upper:]' '[:lower:]')"

auto_generate=true
[[ "$choice" == "n" ]] && auto_generate=false

echo "🔧 Creating WordPress site..."
bash "$SCRIPTS_DIR/cli/website_create.sh" \
  --domain="$domain" \
  --php="$php_version" \
  --auto_generate="$auto_generate" || exit 1