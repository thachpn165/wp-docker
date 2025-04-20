#!/bin/bash
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

wordpress_cli_auto_update_plugin() {
  local domain action
  domain=$(_parse_params "--domain" "$@")
  action=$(_parse_params "--action" "$@")

  _is_missing_param "$domain" "--domain" || return 1
  _is_missing_param "$action" "action" || return 1

  wordpress_auto_update_plugin_logic "$domain" "$action"
}
