#!/usr/bin/env bash

# =======================================
# 💳 ssl_generate_self_signed_menu.sh – Menu for generating self-signed SSL certificate
# =======================================
# ✅ Load configuration from any directory
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
SEARCH_PATH="$SCRIPT_PATH"
while [[ "$SEARCH_PATH" != "/" ]]; do
  if [[ -f "$SEARCH_PATH/shared/config/load_config.sh" ]]; then
    source "$SEARCH_PATH/shared/config/load_config.sh"
    load_config_file
    break
  fi
  SEARCH_PATH="$(dirname "$SEARCH_PATH")"
done

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