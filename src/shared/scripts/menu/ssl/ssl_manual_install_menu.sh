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
safe_source "$CONFIG_FILE"
safe_source "$FUNCTIONS_DIR/ssl_loader.sh"

# === Display the list of websites to the user ===
select_website
if [[ -z "$domain" ]]; then
  print_msf error "$ERROR_NO_WEBSITE_SELECTED"
  exit 1
fi

# === Ask the user for certificate input ===
echo -e "${BLUE}🔹 Paste the certificate file content (.crt) for website (including certificate, CA root,...): ${CYAN}$domain${NC}"
echo -e "${YELLOW}👉 End input by pressing Ctrl+D (on Linux/macOS) or Ctrl+Z then Enter (on Windows Git Bash)${NC}"
echo ""
cat > "$SSL_DIR/$domain.crt"

echo -e "\n${BLUE}🔹 Paste the private key file content (.key) for website: ${CYAN}$domain${NC}"
echo -e "${YELLOW}👉 End input by pressing Ctrl+D or Ctrl+Z as above${NC}"
echo ""
cat > "$SSL_DIR/$domain.key"

# === Run SSL Installation Logic ===
ssl_install_manual_logic "$domain" "$SSL_DIR"