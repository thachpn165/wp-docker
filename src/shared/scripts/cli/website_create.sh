#!/usr/bin/env bash
#shellcheck disable=SC1091

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

# Load functions for website management
source "$FUNCTIONS_DIR/website_loader.sh"

website_prompt_create() {
  #echo -e "${BLUE}===== CREATE NEW WORDPRESS WEBSITE =====${NC}"
  print_msg title "$TITLE_CREATE_NEW_WORDPRESS_WEBSITE"
  # Lấy domain từ người dùng
  read -p "$PROMPT_ENTER_DOMAIN: " domain

  php_choose_version || return 1
  php_version="$REPLY"

  echo ""
  choice=$(get_input_or_test_value "$PROMPT_WEBSITE_CREATE_RANDOM_ADMIN" "${TEST_WEBSITE_CREATE_RANDOM_ADMIN:-y}")
  echo "🔍 Prompt text: $PROMPT_WEBSITE_CREATE_RANDOM_ADMIN"
  choice="$(echo "$choice" | tr '[:upper:]' '[:lower:]')"

  auto_generate=true
  [[ "$choice" == "n" ]] && auto_generate=false

  print_and_debug "🐝 PHP version: $php_version"
  print_and_debug "🐝 Domain: $domain"

  website_cli_create \
    --domain="$domain" \
    --php="$php_version" \
    --auto_generate="$auto_generate" || return 1
}

website_cli_create() {
  auto_generate=true # default: true
  domain=$(website_domain_param "$@")
  php_version=$(website_php_param "$@")
  auto_generate=$(website_auto_generate_param "$@")

  if [[ -z "$domain" || -z "$php_version" ]]; then
    #echo "${CROSSMARK} Missing parameters. Usage:"
    print_msg error "$ERROR_MISSING_PARAM: --domain & --php"
    exit 1
  fi

  website_logic_create "$domain" "$php_version"
  website_setup_wordpress_logic "$domain" "$auto_generate"

  ## Debugging
  debug_log "Domain: $domain"
  debug_log "PHP Version: $php_version"
  debug_log "Auto-generate: $auto_generate"
  debug_log "Website creation process completed."
}
