#!/bin/bash
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
safe_source "$FUNCTIONS_DIR/wordpress_loader.sh"

website_cli_update_template() {
  # === Parse command line flags ===
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --domain=*)
      domain="${1#*=}"
      shift
      ;;
    --action=*)
      action="${1#*=}"
      shift
      ;;
    *)
      #echo "Unknown parameter: $1"
      print_and_debug error "$ERROR_UNKNOW_PARAM: $1"
      exit 1
      ;;
  esac
done

# Ensure valid parameters are passed
if [ -z "$domain" ] || [ -z "$action" ]; then
  #echo "${CROSSMARK} Missing required parameters: --domain and --action"
  print_and_debug error "$ERROR_MISSING_PARAM: --domain & --action"
  exit 1
fi

# === Call the logic function to update plugin auto-update settings ===
  website_logic_update_template "$domain" "$action"
}
