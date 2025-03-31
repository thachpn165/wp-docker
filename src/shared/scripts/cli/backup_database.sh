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
    --db_name=*)
      db_name="${1#*=}"
      shift
      ;;
    --db_user=*)
      db_user="${1#*=}"
      shift
      ;;
    --db_pass=*)
      db_pass="${1#*=}"
      shift
      ;;
    *)
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
done

# Ensure valid parameters are passed
if [ -z "$site_name" ] || [ -z "$db_name" ] || [ -z "$db_user" ] || [ -z "$db_pass" ]; then
  echo "❌ Missing required parameters: --site_name, --db_name, --db_user, and --db_pass"
  exit 1
fi

# Call the logic function to backup the database
backup_database_logic "$site_name" "$db_name" "$db_user" "$db_pass"
