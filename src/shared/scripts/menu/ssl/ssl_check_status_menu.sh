#!/usr/bin/env bash

# ============================================
# ✅ SSL Certificate Check Status Menu for Website
# ============================================

# === Load config & website_loader.sh ===
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

CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi
source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/ssl_loader.sh"

# === Display website selection menu ===
select_website

# Ensure a site is selected
if [[ -z "$SITE_NAME" ]]; then
  echo "❌ No website selected."
  exit 1
fi

if [[ $? -eq 0 ]]; then
  # === Call the CLI for checking SSL certificate status ===
  echo -e "${GREEN}✅ Checking SSL certificate status for '$SITE_NAME'...${NC}"
  bash "$SCRIPTS_DIR/cli/ssl_check_status.sh" --site_name="$SITE_NAME"
else
  echo -e "${YELLOW}⚠️ SSL certificate check cancelled.${NC}"
fi