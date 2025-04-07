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

# 📋 Chọn website
select_website
if [[ -z "$domain" ]]; then
  print_msg error "$ERROR_NO_WEBSITE_SELECTED"
  exit 1
fi

# 📋 Hiển thị danh sách admin
print_msg info "$INFO_WORDPRESS_LIST_ADMINS"
bash "$CLI_DIR/wordpress_wp_cli.sh" --domain="$domain" -- user list --role=administrator --fields=ID,user_login --format=table
echo ""

# 🔐 Nhập user ID
user_id=$(get_input_or_test_value "$PROMPT_WORDPRESS_ENTER_USER_ID" "${TEST_USER_ID:-0}")
if [[ -z "$user_id" ]]; then
  print_msg error "$ERROR_INPUT_REQUIRED"
  exit 1
fi

# ▶️ Gọi CLI thực hiện reset
bash "$CLI_DIR/wordpress_reset_admin_passwd.sh" --domain="$domain" --user_id="$user_id"