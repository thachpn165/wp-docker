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

# Ensure SITE_NAME is set by calling select_website
select_website || exit 1

# Check if SITE_NAME is still empty
if [[ -z "$SITE_NAME" ]]; then
    echo "${CROSSMARK} Site name is not set. Exiting..."
    exit 1
fi

# Display a warning about the action
echo -e "\n${WARNING} WARNING: This action will RESET the database for the selected website '$SITE_NAME'. All data in the database will be lost permanently!"
echo "Please ensure you have backed up the data before proceeding."
read -rp "Do you want to proceed? (y/n): " confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "${CROSSMARK} Action canceled. No changes were made."
  exit 0
fi

# Call cli/database_reset.sh with the selected site_name as parameter
bash "$CLI_DIR/database_reset.sh" --site_name="$SITE_NAME"