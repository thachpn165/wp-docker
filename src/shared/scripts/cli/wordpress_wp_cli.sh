#!/bin/bash
# ======================================
# CLI wrapper: Run WP-CLI inside container for a given site
# ======================================
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
source "$FUNCTIONS_DIR/wordpress_loader.sh"

# === Parse arguments ===
domain=""
params=()

for arg in "$@"; do
  case $arg in
    --domain=*) domain="${arg#*=}" ;;
    #*) params+=("$arg") ;;
    *)
      if [[ "$arg" == --* ]]; then
        print_and_debug error "$ERROR_UNKNOW_PARAM: $arg"
        exit 1
      else
        params+=("$arg")
      fi
      ;;
  esac
done

if [[ -z "$domain" ]]; then
  #echo -e "${RED}${CROSSMARK} Missing required --domain=SITE_DOMAIN parameter.${NC}"
  print_and_debug error "$ERROR_MISSING_PARAM: --domain"
  #echo "Usage: $0 --domain=SITE_DOMAIN wp-cli-commands..."
  print_msg tip "$INFO_PARAM_EXAMPLE:\n  --domain=example.tld wp plugin list"
  exit 1
fi

if [[ ${#params[@]} -eq 0 ]]; then
  #echo -e "${RED}${CROSSMARK} You must provide a WP-CLI command to run.${NC}"
  print_and_debug error "$ERROR_WPCLI_INVALID_PARAMS"
  #echo "Example: $0 --domain=wpdocker.dev plugin list"
  print_msg tip "$INFO_PARAM_EXAMPLE:\n  --domain=example.tld plugin list"
  exit 1
fi

# === Call logic ===
wordpress_wp_cli_logic "$domain" "${params[@]}"