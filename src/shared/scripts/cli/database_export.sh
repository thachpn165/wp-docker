#!/bin/bash

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
timestamp=$(date +%s)
# Initial checks
if [ -z "$1" ]; then
  echo "Usage: $0 --site_name <site_name> [--save_location <path>]"
  exit 1
fi

# Parse parameters
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --site_name=*) site_name="${1#*=}" ;;
        --save_location=*) save_location="${1#*=}" ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done
save_location="${SITES_DIR}/$site_name/backups/${site_name}-backup-$(date +%F)-$timestamp.sql"
# Ensure site_name is set
if [[ -z "$site_name" ]]; then
    echo "${CROSSMARK} Missing required parameter: --site_name"
    exit 1
fi

# If save_location is still not defined, set it to default value
if [[ -z "$save_location" ]]; then
    save_location="${SITES_DIR}/$site_name/backups/${site_name}-backup-$(date +%F)-$timestamp.sql"
fi

# Call the database export logic
database_export_logic "$site_name" "$save_location"