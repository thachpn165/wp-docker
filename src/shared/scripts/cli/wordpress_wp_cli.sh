#!/bin/bash

# =============================================
# 🧩 wordpress_wp_cli.sh – Run WP-CLI inside container for a WordPress site
# =============================================
# Description:
#   - Executes any WP-CLI command inside the PHP container of the specified domain.
#
# Usage:
#   ./wordpress_wp_cli.sh --domain=example.tld -- plugin list
#
# Parameters:
#   --domain=<domain>     (required)
#   --                    (separator before actual wp-cli args)
# =============================================

# === Auto-detect BASE_DIR and load configuration ===
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

# === Load WordPress-related functions ===
safe_source "$FUNCTIONS_DIR/wordpress_loader.sh"

# === Parse arguments ===
domain=""
params=()
parse_wp_args=false

for arg in "$@"; do
  if [[ "$arg" == "--" ]]; then
    parse_wp_args=true
    continue
  fi

  if [[ "$parse_wp_args" == true ]]; then
    params+=("$arg")
  else
    case "$arg" in
      --domain=*) domain="${arg#*=}" ;;
      --domain) shift; domain="$1" ;;
      *)
        print_and_debug error "$ERROR_UNKNOW_PARAM: $arg"
        print_msg tip "$INFO_PARAM_EXAMPLE:\n  --domain=example.tld -- plugin list"
        exit 1
        ;;
    esac
  fi
done

# === Validate parameters ===
_is_missing_param "$domain" "domain" || exit 1
_is_valid_domain "$domain" || exit 1

if [[ ${#params[@]} -eq 0 ]]; then
  print_and_debug error "$ERROR_WPCLI_INVALID_PARAMS"
  print_msg tip "$INFO_PARAM_EXAMPLE:\n  --domain=example.tld -- plugin list"
  exit 1
fi

# === Execute logic ===
wordpress_wp_cli_logic "$domain" "${params[@]}"