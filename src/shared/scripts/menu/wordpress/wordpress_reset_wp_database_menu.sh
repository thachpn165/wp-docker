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

# 🔥 Hiển thị cảnh báo quan trọng
clear
print_msg important "$IMPORTANT_RESET_DATABASE_TITLE"
print_msg error "$ERROR_RESET_DATABASE_WARNING"
print_msg warning "$WARNING_BACKUP_BEFORE_CONTINUE"
echo ""

# 📋 Hiển thị danh sách website để chọn
print_msg info "$INFO_LIST_WEBSITES_FOR_DB_RESET"
select_website
if [[ -z "$domain" ]]; then
  print_msg error "$ERROR_NO_WEBSITE_SELECTED"
  exit 1
fi

# ✅ Xác nhận hành động reset database
echo ""
print_msg warning "$(printf "$CONFIRM_RESET_DATABASE_FOR_SITE" "$domain")"
echo "1) ✅ $CONFIRM_YES_RESET_DATABASE"
echo "2) ❌ $CONFIRM_NO_CANCEL"
get_input_or_test_value "$PROMPT_SELECT_OPTION" confirm_choice

if [[ "$confirm_choice" == "1" ]]; then
  bash "$SCRIPTS_DIR/cli/wordpress_reset_wp_database.sh" --domain="$domain"
  print_msg success "$(printf "$SUCCESS_DATABASE_RESET_DONE" "$domain")"
elif [[ "$confirm_choice" == "2" ]]; then
  print_msg warning "$WARNING_RESET_DATABASE_CANCELLED"
else
  print_msg error "$ERROR_SELECT_OPTION_INVALID"
  exit 1
fi