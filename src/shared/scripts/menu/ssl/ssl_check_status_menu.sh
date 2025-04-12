#!/usr/bin/env bash

# ============================================
# ${CHECKMARK} SSL Certificate Check Status Menu for Website
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
  echo "${CROSSMARK} Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi
safe_source "$CONFIG_FILE"
safe_source "$FUNCTIONS_DIR/ssl_loader.sh"

# === Display website selection menu ===
select_website

# Ensure a site is selected
if [[ -z "$domain" ]]; then
  print_msf error "$ERROR_NO_WEBSITE_SELECTED"
  exit 1
fi

if [[ $? -eq 0 ]]; then
  # === Call the CLI for checking SSL certificate status ===
  echo -e "${GREEN}${CHECKMARK} Checking SSL certificate status for '$domain'...${NC}"
  bash "$SCRIPTS_DIR/cli/ssl_check_status.sh" --domain="$domain"
else
  echo -e "${YELLOW}${WARNING} SSL certificate check cancelled.${NC}"
fi