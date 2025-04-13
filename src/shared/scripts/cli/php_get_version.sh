#!/bin/bash

# =====================================
# 🧪 php_cli_get_version – CLI wrapper to get PHP versions from Docker Hub
# =====================================

# === Auto-detect BASE_DIR and load config ===
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
  if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
    source "$SCRIPT_PATH/shared/config/load_config.sh"
    break
  fi
  SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done

# === Load PHP-related logic ===
safe_source "$FUNCTIONS_DIR/php_loader.sh"

# === Execute main logic ===
php_get_version