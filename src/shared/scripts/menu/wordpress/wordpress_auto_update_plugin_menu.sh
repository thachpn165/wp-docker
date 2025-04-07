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
  print_msg error "$ERROR_SITE_NOT_SELECTED"
  exit 1
fi

# 📋 Prompt action
print_msg info "$(printf "$PROMPT_CHOOSE_ACTION_FOR_SITE" "$domain")"
echo "1) $LABEL_ENABLE_AUTO_UPDATE_PLUGIN"
echo "2) $LABEL_DISABLE_AUTO_UPDATE_PLUGIN"

get_input_or_test_value "$PROMPT_ENTER_OPTION" action_choice

if [[ "$action_choice" == "1" ]]; then
  action="enable"
elif [[ "$action_choice" == "2" ]]; then
  action="disable"
else
  print_msg error "$ERROR_SELECT_OPTION_INVALID"
  exit 1
fi

# ▶️ Execute CLI
bash "$SCRIPTS_DIR/cli/wordpress_auto_update_plugin.sh" --domain="$domain" --action="$action"