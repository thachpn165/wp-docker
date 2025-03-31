#!/bin/bash

# === Load config & system_loader.sh ===
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
source "$FUNCTIONS_DIR/backup_loader.sh"

# === Parse command line flags ===
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --site_name=*)
      site_name="${1#*=}"
      shift
      ;;
    --code_backup_file=*)
      code_backup_file="${1#*=}"
      shift
      ;;
    --db_backup_file=*)
      db_backup_file="${1#*=}"
      shift
      ;;
    --test_mode=*)
      test_mode="${1#*=}"
      shift
      ;;
    *)
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
done

# Ensure site_name is passed, but code_backup_file and db_backup_file can be optional
if [[ -z "$site_name" ]]; then
  echo "❌ Missing site_name parameter."
  exit 1
fi

# Call the logic function to restore the website, passing the necessary parameters
backup_restore_web_logic "$site_name" "$code_backup_file" "$db_backup_file" "$test_mode"