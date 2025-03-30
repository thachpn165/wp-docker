#!/usr/bin/env bash

# =============================================
# 🗑️ website_delete_menu.sh – Delete a website
# =============================================

# Auto-detect PROJECT_DIR
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
source "$FUNCTIONS_DIR/website_loader.sh"

echo -e "${BLUE}===== DELETE A WEBSITE =====${NC}"
site_name=""
select_website
site_name="$SITE_NAME"
if [[ -z "$site_name" ]]; then
  echo "❌ No website selected."
  exit 1
fi

backup_enabled=true
if [[ "$TEST_MODE" != true ]]; then
  echo -e "\n💾 Do you want to backup the website before deletion?"
  read -rp "Type 'yes' to backup, or anything else to skip: " backup_confirm
  if [[ "$backup_confirm" != "yes" ]]; then
    backup_enabled=false
  fi
else
  backup_enabled=false
fi

echo -e "\n⚠️  Are you sure you want to delete site '${YELLOW}$site_name${NC}'?"
read -rp "Type 'yes' to confirm: " confirm
if [[ "$confirm" != "yes" ]]; then
  echo "❌ Cancelled."
  exit 1
fi

# === Run deletion logic ===
if [[ -n "$site_name" && -n "$backup_enabled" ]]; then
  bash "$SCRIPTS_DIR/cli/website_delete.sh" --site="$site_name" --backup="$backup_enabled"
else
  echo "❌ Missing required parameters to delete website." >&2
  exit 1
fi
