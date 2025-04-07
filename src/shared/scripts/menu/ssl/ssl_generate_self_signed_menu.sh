#!/usr/bin/env bash

# =======================================
# 💳 ssl_generate_self_signed_menu.sh – Menu for generating self-signed SSL certificate
# =======================================

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
  echo "${CROSSMARK} Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi
source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/ssl_loader.sh"

# === Select website to generate SSL ===
select_website
if [[ -z "$domain" ]]; then
  print_msf error "$ERROR_NO_WEBSITE_SELECTED"
  exit 1
fi

# === Display selected website for SSL creation ===
echo -e "${GREEN}You have selected website: $domain${NC}"
echo -e "${YELLOW}Now generating self-signed SSL for '$domain'...${NC}"

# Call the logic to generate SSL (This will be handled in your CLI)
bash "$SCRIPTS_DIR/cli/ssl_generate_self_signed.sh" --domain="$domain"