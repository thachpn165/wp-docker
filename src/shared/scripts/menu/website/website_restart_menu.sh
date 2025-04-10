#!/usr/bin/env bash

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

# === Input handling ===
auto_generate=true   # default: true
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --domain=*) domain="${1#*=}" ;;
    --php=*) php_version="${1#*=}" ;;
    --auto_generate=*) auto_generate="${1#*=}" ;;
    *)
      print_msg error "$ERROR_UNKNOW_PARAM: $1"
      print_msg info "$INFO_PARAM_EXAMPLE:\n  --domain=example.com --php=8.2"
      exit 1
      ;;
  esac
  shift
done
#if [[ -z "$domain" || ]] 
if [[ -z "$domain" || -z "$php_version" ]]; then
  #echo "${CROSSMARK} Missing parameters. Usage:"
  print_msg error "$ERROR_MISSING_PARAM: --domain & --php"
  exit 1
fi


website_management_create_logic "$domain" "$php_version"
website_setup_wordpress_logic "$domain" "$auto_generate"

## Debugging
debug_log "Domain: $domain"
debug_log "PHP Version: $php_version"
debug_log "Auto-generate: $auto_generate"
debug_log "Website creation process completed."
source "$FUNCTIONS_DIR/website_loader.sh"

# === Display the list of websites to the user ===
select_website
if [[ -z "$domain" ]]; then
  print_msf error "$ERROR_NO_WEBSITE_SELECTED"
  exit 1
fi

# === Ask the user if they want to restart the selected website ===
echo -e "${YELLOW}⚡ You are about to restart the website '$domain'. Are you sure?${NC}"
confirm_action "Do you want to proceed?"

if [[ $? -eq 0 ]]; then
  # === Call the CLI for restarting the website, pass --domain correctly ===
  echo -e "${GREEN}${CHECKMARK} Restarting website '$domain'...${NC}"
  bash "$SCRIPTS_DIR/cli/website_restart.sh" --domain="$domain"  # Fixed here, passing --site
  echo -e "${GREEN}${CHECKMARK} Website '$domain' has been restarted successfully.${NC}"
else
  echo -e "${YELLOW}${WARNING} Website restart cancelled.${NC}"
fi