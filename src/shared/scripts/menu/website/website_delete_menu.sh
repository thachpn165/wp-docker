#!/usr/bin/env bash
# 🔧 Auto-detect BASE_DIR and load global configuration
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
  if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
    source "$SCRIPT_PATH/shared/config/load_config.sh"
    break
  fi
  SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done

# Load backup-related scripts
source "$FUNCTIONS_DIR/backup_loader.sh"

#echo -e "${BLUE}===== DELETE A WEBSITE =====${NC}"
print_msg title "$TITLE_WEBSITE_DELETE"
domain=""
select_website
if [[ -z "$domain" ]]; then
  print_msg error "$ERROR_NO_WEBSITE_SELECTED"
  exit 1
fi

# Prompt the user for backup confirmation
backup_enabled=true
if [[ "$TEST_MODE" != true ]]; then
  backup_confirm=$(get_input_or_test_value "$PROMPT_BACKUP_BEFORE_DELETE $domain (${YELLOW}yes${NC}/${RED}no${NC}) " "no")
  if [[ "$backup_confirm" != "yes" ]]; then
    backup_enabled=false
  fi
  else
    backup_enabled=false
  fi

confirm=$(get_input_or_test_value "$PROMPT_WEBSITE_DELETE_CONFIRM $domain (${YELLOW}yes${NC}/${RED}no${NC}) " "yes")
if [[ "$confirm" != "yes" ]]; then
  echo "${CROSSMARK} Cancelled."
  exit 1
fi

# === Run deletion logic ===
if [[ -n "$domain" ]]; then
  if [[ "$backup_enabled" == true ]]; then
    bash "$SCRIPTS_DIR/cli/website_delete.sh" --domain="$domain" --backup_enabled=true
  else
    bash "$SCRIPTS_DIR/cli/website_delete.sh" --domain="$domain"
  fi
else
  print_msg error "$ERROR_MISSING_PARAM: --domain"
  exit 1
fi
