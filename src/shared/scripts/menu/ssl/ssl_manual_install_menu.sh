#!/usr/bin/env bash

# ============================================
# ${CHECKMARK} ssl_manual_install_menu.sh – Menu for SSL Installation
# ============================================

# === Load config & logic ===
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

# === Display the list of websites to the user ===
select_website
site_name="$SITE_NAME"
if [[ -z "$site_name" ]]; then
  echo "${CROSSMARK} No website selected."
  exit 1
fi

# === Ask the user for certificate input ===
echo -e "${BLUE}🔹 Paste the certificate file content (.crt) for website (including certificate, CA root,...): ${CYAN}$site_name${NC}"
echo -e "${YELLOW}👉 End input by pressing Ctrl+D (on Linux/macOS) or Ctrl+Z then Enter (on Windows Git Bash)${NC}"
echo ""
cat > "$SSL_DIR/$site_name.crt"

echo -e "\n${BLUE}🔹 Paste the private key file content (.key) for website: ${CYAN}$site_name${NC}"
echo -e "${YELLOW}👉 End input by pressing Ctrl+D or Ctrl+Z as above${NC}"
echo ""
cat > "$SSL_DIR/$site_name.key"

# === Run SSL Installation Logic ===
ssl_install_manual_logic "$site_name" "$SSL_DIR"