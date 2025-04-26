#!/bin/bash
# ==================================================
# File: php_get_version.sh
# Description: CLI wrapper to retrieve PHP versions from Docker Hub.
# Functions:
#   - php_get_version: Retrieve and display available PHP versions.
#       Parameters: None.
#       Returns: None.
# ==================================================

# Auto-detect BASE_DIR and load config
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
  if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
    source "$SCRIPT_PATH/shared/config/load_config.sh"

    load_config_file
    break
  fi
  SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done

# Load PHP-related logic
safe_source "$FUNCTIONS_DIR/php/php_get_version.sh"

# Execute main logic
php_get_version