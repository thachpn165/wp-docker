#!/usr/bin/env bash

# ============================================
# ${CHECKMARK} ssl_edit_cert_menu.sh – Edit SSL Certificate via Menu
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

# === Select Website ===
select_website
if [[ -z "$domain" ]]; then
  print_msf error "$ERROR_NO_WEBSITE_SELECTED"
  exit 1
fi

# === Ask the user for certificate update options ===
echo -e "${YELLOW}⚡ You are about to edit SSL certificate for '$domain'. Are you sure?${NC}"
confirm_action "Do you want to proceed?"

if [[ $? -eq 0 ]]; then
  # === Request user to input SSL Certificate and Private Key ===
  echo -e "${YELLOW}Please enter the SSL certificate content for '$domain':"
  read -r ssl_certificate

  echo -e "${YELLOW}Please enter the SSL private key content for '$domain':"
  read -r ssl_private_key

  # === Call the SSL edit logic directly, no need for CLI here ===
  echo -e "${GREEN}${CHECKMARK} Editing SSL certificate for website '$domain'...${NC}"
  ssl_logic_edit_cert "$domain" "$ssl_certificate" "$ssl_private_key"
else
  echo -e "${YELLOW}${WARNING} SSL certificate update cancelled.${NC}"
fi