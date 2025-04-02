#!/usr/bin/env bash

# ============================================
# ✅ Install Let's Encrypt SSL Certificate Menu
# ============================================

# === Load configuration and logic ===
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

# === Ask for website and email ===
echo -e "${YELLOW}🔧 Please select the website for which you want to install the SSL certificate:${NC}"
select_website
SITE_NAME="$SITE_NAME"

if [[ -z "$SITE_NAME" ]]; then
  echo -e "${RED}❌ No website selected. Exiting.${NC}"
  exit 1
fi

echo -e "${YELLOW}🔧 Please provide the email address for Let's Encrypt registration:${NC}"
read -p "Email: " EMAIL

if [[ -z "$EMAIL" ]]; then
  echo -e "${RED}❌ Email is required for Let's Encrypt registration. Exiting.${NC}"
  exit 1
fi

# Staging is always set to false
STAGING=false

# === Call the logic to install Let's Encrypt SSL ===
ssl_install_lets_encrypt_logic "$SITE_NAME" "$EMAIL" "$STAGING"