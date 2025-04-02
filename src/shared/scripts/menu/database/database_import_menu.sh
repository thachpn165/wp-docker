#!/bin/bash

if [ -z "$BASH_VERSION" ]; then
  echo "${CROSSMARK} This script must be run in a Bash shell." >&2
  exit 1
fi

# Ensure PROJECT_DIR is set
if [[ -z "$PROJECT_DIR" ]]; then
  SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
  
  # Iterate upwards from the current script directory to find 'config.sh'
  while [[ "$SCRIPT_PATH" != "/" ]]; do
    if [[ -f "$SCRIPT_PATH/shared/config/config.sh" ]]; then
      PROJECT_DIR="$SCRIPT_PATH"
      break
    fi
    SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
  done

  # Handle error if config file is not found
  if [[ -z "$PROJECT_DIR" ]]; then
    echo "${CROSSMARK} Unable to determine PROJECT_DIR. Please check the script's directory structure." >&2
    exit 1
  fi
fi

# Load the config file if PROJECT_DIR is set
CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "${CROSSMARK} Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi

# Source the config file
source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/database_loader.sh"

echo "🔧 Choose the website for database import:"
select_website || exit 1

# Ensure SITE_NAME is selected
if [[ -z "$SITE_NAME" ]]; then
    echo "${CROSSMARK} Site name is not set. Exiting..."
    exit 1
fi

# Ask for the .sql file path
read -rp "Enter .sql file path: " backup_file

# Ensure the file path is provided
if [[ -z "$backup_file" ]]; then
    echo "${CROSSMARK} No file path provided. Exiting..."
    exit 1
fi

echo "💾 Importing database for site: $SITE_NAME from backup file: $backup_file"

# Call cli/database_import.sh with the selected site_name, db_user, db_password, db_name, and backup_file
bash "$CLI_DIR/database_import.sh" --site_name="$SITE_NAME" --backup_file="$backup_file"