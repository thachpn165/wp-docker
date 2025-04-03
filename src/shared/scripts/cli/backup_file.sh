#!/bin/bash
# backup_file.sh
#
# This script is used to back up files for a specific site within a project directory.
# It ensures the script is executed in a Bash shell, validates the project directory,
# loads necessary configuration and functions, and processes command-line arguments
# to perform the backup operation.
#
# Usage:
#   ./backup_file.sh --domain=example.tld
#
# Parameters:
#   --domain=example.tld : (Required) The name of the site to back up.
#
# Behavior:
#   - Ensures the script is executed directly in a Bash shell.
#   - Determines the PROJECT_DIR by traversing the directory structure.
#   - Validates the presence of the configuration file and functions directory.
#   - Loads the configuration file and backup-related functions.
#   - Parses the command-line arguments to extract the site name.
#   - Calls the `backup_file_logic` function to perform the backup operation.
#
# Prerequisites:
#   - The script must be executed directly, not sourced.
#   - The PROJECT_DIR must contain the `shared/config/config.sh` file.
#   - The `shared/scripts/functions/backup_loader.sh` script must exist and be valid.
#
# Exit Codes:
#   1 : If the script is not executed in a Bash shell.
#   1 : If the script is sourced instead of executed directly.
#   1 : If the PROJECT_DIR cannot be determined.
#   1 : If the configuration file is missing.
#   1 : If the functions directory is missing.
#   1 : If an unknown parameter is passed.
#   1 : If the required `--domain` parameter is missing.
#
# Example:
#   ./backup_file.sh --domain=my_site
#
# Notes:
#   - Ensure the directory structure and required files are correctly set up
#     before executing this script.
#   - The `backup_file_logic` function must be defined in the loaded functions
#     to handle the actual backup process.

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

# Load backup-related scripts
source "$FUNCTIONS_DIR/backup_loader.sh"

# === Parse command line flags ===
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --domain=*)
      domain="${1#*=}"
      shift
      ;;
    *)
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
done

# Ensure valid parameters are passed
if [ -z "$domain" ]; then
  echo "${CROSSMARK} Missing required parameter: --domain"
  exit 1
fi

# === Call the logic function to backup files ===
backup_file_logic "$domain"
