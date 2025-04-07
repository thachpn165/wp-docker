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

# 📋 Select website
select_website
if [[ -z "$domain" ]]; then
  print_msg error "$ERROR_NO_WEBSITE_SELECTED"
  exit 1
fi

# 📋 Choose action
echo ""
print_msg question "$(printf "$QUESTION_PROTECT_WPLOGIN_ACTION" "$domain")"
echo "1) $LABEL_PROTECT_WPLOGIN_ENABLE"
echo "2) $LABEL_PROTECT_WPLOGIN_DISABLE"

action_choice=$(get_input_or_test_value "$PROMPT_ENTER_ACTION_NUMBER" "${TEST_ACTION:-1}")

if [[ "$action_choice" == "1" ]]; then
    action="enable"
elif [[ "$action_choice" == "2" ]]; then
    action="disable"
else
    print_msg error "$ERROR_INVALID_CHOICE"
    exit 1
fi

# ▶️ Run CLI
bash "$CLI_DIR/wordpress_protect_wp_login.sh" --domain="$domain" --action="$action"