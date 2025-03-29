#!/bin/bash
# =====================================
# 🐋 website_management_create – Create New WordPress Website
# =====================================


# === Auto-detect PROJECT_DIR (source code root) ===
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

# === ✅ Load config.sh from PROJECT_DIR ===
CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi
source "$CONFIG_FILE"

# Load config and dependent functions
source "$SCRIPTS_FUNCTIONS_DIR/website/website_management_create.sh"
source "$FUNCTIONS_DIR/website/website_create_env.sh"
source "$SCRIPTS_FUNCTIONS_DIR/php/php_choose_version.sh"
source "$SCRIPTS_FUNCTIONS_DIR/nginx/nginx_utils.sh"
source "$SCRIPTS_FUNCTIONS_DIR/file_utils.sh"
source "$SCRIPTS_FUNCTIONS_DIR/misc_utils.sh"
source "$SCRIPTS_FUNCTIONS_DIR/website/website_update_site_template.sh"

# Run main function
website_management_create