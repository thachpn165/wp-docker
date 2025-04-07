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

# === Display welcome message ===
print_msg title "$TITLE_MIGRATION_TOOL"
echo ""
print_msg warning "$WARNING_MIGRATION_PREPARE"
echo "  - $TIP_MIGRATION_FOLDER_PATH: ${BLUE}$INSTALL_DIR/archives/domain.ltd${NC}"
echo "  - $TIP_MIGRATION_FOLDER_CONTENT"
echo "     - $TIP_MIGRATION_SOURCE"
echo "     - $TIP_MIGRATION_SQL"
echo ""

# === Confirm user is ready ===
get_input_or_test_value "$QUESTION_MIGRATION_READY" ready
if [[ "$ready" != "y" && "$ready" != "Y" ]]; then
  print_msg error "$ERROR_MIGRATION_CANCEL"
  exit 1
fi

echo ""
get_input_or_test_value "$PROMPT_ENTER_DOMAIN_TO_MIGRATE" domain
if [[ -z "$domain" ]]; then
  print_msg error "$ERROR_DOMAIN_REQUIRED"
  exit 1
fi

echo ""
print_msg info "$(printf "$INFO_MIGRATION_STARTING" "$domain")"
bash "$CLI_DIR/wordpress_migration.sh" --domain="$domain"