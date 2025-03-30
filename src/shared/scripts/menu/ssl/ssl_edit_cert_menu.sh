#!/usr/bin/env bash

# ============================================
# ✅ ssl_edit_cert_menu.sh – Edit SSL Certificate via Menu
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

# === Select Website ===
select_website
site_name="$SITE_NAME"
if [[ -z "$site_name" ]]; then
  echo "❌ No website selected."
  exit 1
fi

# === Ask the user for certificate update options ===
echo -e "${YELLOW}⚡ You are about to edit SSL certificate for '$site_name'. Are you sure?${NC}"
confirm_action "Do you want to proceed?"

if [[ $? -eq 0 ]]; then
  # === Request user to input SSL Certificate and Private Key ===
  echo -e "${YELLOW}Please enter the SSL certificate content for '$site_name':"
  read -r ssl_certificate

  echo -e "${YELLOW}Please enter the SSL private key content for '$site_name':"
  read -r ssl_private_key

  # === Call the SSL edit logic directly, no need for CLI here ===
  echo -e "${GREEN}✅ Editing SSL certificate for website '$site_name'...${NC}"
  ssl_edit_certificate_logic "$site_name" "$ssl_certificate" "$ssl_private_key"
else
  echo -e "${YELLOW}⚠️ SSL certificate update cancelled.${NC}"
fi