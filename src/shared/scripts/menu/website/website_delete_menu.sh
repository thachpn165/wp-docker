#!/usr/bin/env bash

# ========================================
# 🧩 website_delete_menu.sh – Website deletion with optional backup
# ========================================

# 🔧 Auto-detect BASE_DIR and load global configuration
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
  if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
    source "$SCRIPT_PATH/shared/config/load_config.sh"
    break
  fi
  SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done

# === Load required functions ===
source "$FUNCTIONS_DIR/backup_loader.sh"

# === UI ===
print_msg title "$TITLE_WEBSITE_DELETE"

# Select website
domain=""
select_website
if [[ -z "$domain" ]]; then
  print_msg error "$ERROR_NO_WEBSITE_SELECTED"
  exit 1
fi

# Ask for backup before delete
backup_enabled=true  # default
backup_confirm=$(get_input_or_test_value "$PROMPT_BACKUP_BEFORE_DELETE $domain (${YELLOW}yes${NC}/${RED}no${NC}) " "yes")
[[ "$backup_confirm" != "yes" ]] && backup_enabled=false
debug_log "[DEBUG] Backup before delete: $backup_enabled"

# Ask for final delete confirmation
delete_confirm=$(get_input_or_test_value "$PROMPT_WEBSITE_DELETE_CONFIRM $domain (${YELLOW}yes${NC}/${RED}no${NC}) " "no")
if [[ "$delete_confirm" != "yes" ]]; then
  print_msg warning "$WARNING_ACTION_CANCELLED"
  exit 0
fi

# Run deletion logic
cmd="bash \"$SCRIPTS_DIR/cli/website_delete.sh\" --domain=\"$domain\""
[[ "$backup_enabled" == true ]] && cmd+=" --backup_enabled=true"
debug_log "[DEBUG] Command sent to cli/website_delete.sh: $cmd"

eval "$cmd"