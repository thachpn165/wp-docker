#!/bin/bash

# === Load config & wordpress_loader.sh ===
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

CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi

source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/wordpress_loader.sh"

# ⚠️ Cảnh báo trước khi reset quyền
print_msg warning "$WARNING_RESET_ADMIN_ROLE_1"
print_msg warning "$WARNING_RESET_ADMIN_ROLE_2"

# 📋 Chọn website
print_msg info "$INFO_LIST_WEBSITES_RESET"
select_website
if [[ -z "$domain" ]]; then
  print_msg error "$ERROR_NO_WEBSITE_SELECTED"
  exit 1
fi

# ▶️ Gọi CLI để reset quyền
bash "$SCRIPTS_DIR/cli/wordpress_reset_user_role.sh" --domain="$domain"