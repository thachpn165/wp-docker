#!/bin/bash

# ============================================
# Script Name: backup_database.sh
# Description: This script is used to back up a database for a specified site.
#              It loads the necessary configuration and functions, parses command-line
#              arguments, and invokes the backup logic.
#
# Usage:
#   ./backup_database.sh --site_name=<site_name> --db_name=<db_name> --db_user=<db_user> --db_pass=<db_pass>
#
# Parameters:
#   --site_name   : The name of the site for which the database backup is being created.
#   --db_name     : The name of the database to back up.
#   --db_user     : The username for accessing the database.
#   --db_pass     : The password for accessing the database.
#
# Requirements:
#   - The script must be executed in an environment where the PROJECT_DIR variable
#     can be determined or set.
#   - The configuration file (config.sh) must exist in the shared/config directory.
#   - The backup_loader.sh script must be available in the FUNCTIONS_DIR.
#
# Exit Codes:
#   0 : Success
#   1 : Failure due to missing configuration file, invalid parameters, or unknown flags.
#
# Example:
#   ./backup_database.sh --site_name=my_site --db_name=my_db --db_user=my_user --db_pass=my_password
#
# ============================================


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
  echo "${CROSSMARK} Missing required parameters: --site_name, --db_name, --db_user, and --db_pass"
  exit 1
fi

# Call the logic function to backup the database
backup_database_logic "$site_name" "$db_name" "$db_user" "$db_pass"
