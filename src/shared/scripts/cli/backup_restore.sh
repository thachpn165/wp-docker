#!/bin/bash

# 🔧 Auto-detect BASE_DIR and load global configuration
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
  if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
    source "$SCRIPT_PATH/shared/config/load_config.sh"
    break
  fi
  SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done
source "$FUNCTIONS_DIR/backup_loader.sh"

backup_cli_restore_web() {
  local domain
  local code_backup_file
  local db_backup_file
  local test_mode
  # Parse command line flags
  domain=$(_parse_params "--domain" "$@")
  code_backup_file=$(_parse_params "--code_backup_file" "$@")
  db_backup_file=$(_parse_params "--db_backup_file" "$@")
  test_mode=$(_parse_optional_params "--test_mode" "$@")

  # Ensure all params are provided
  if [[ $? -ne 0 ]]; then
    print_msg error "$ERROR_MISSING_PARAM: --domain, --code_backup_file, --db_backup_file"
    return 1
  fi

  # Call the logic function to restore the website, passing the necessary parameters
  backup_logic_restore_web "$domain" "$code_backup_file" "$db_backup_file" "$test_mode"
}
