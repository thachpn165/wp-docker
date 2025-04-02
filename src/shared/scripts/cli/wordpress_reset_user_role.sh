#!/bin/bash
# -----------------------------------------------------------------------------
# Script Name: wordpress_reset_user_role.sh
# Description: This script resets the user role for a specified WordPress site.
#              It ensures the script is run in a Bash shell, determines the 
#              project directory, loads the necessary configuration, and 
#              executes the logic to reset the user role.
#
# Usage:
#   ./wordpress_reset_user_role.sh --site_name=<site_name>
#
# Parameters:
#   --site_name=<site_name> : (Required) The name of the WordPress site for 
#                             which the user role needs to be reset.
#
# Prerequisites:
#   - The script must be executed in a Bash shell.
#   - The PROJECT_DIR environment variable must be correctly set, or the script
#     must be located within a directory structure containing 'config.sh'.
#   - The 'config.sh' file and 'wordpress_loader.sh' script must exist and be 
#     properly configured.
#
# Exit Codes:
#   1 : General error (e.g., missing parameters, invalid environment).
#   2 : Config file or required scripts not found.
#
# Example:
#   ./wordpress_reset_user_role.sh --site_name=my_wordpress_site
#
# -----------------------------------------------------------------------------

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
    echo "❌ Unable to determine PROJECT_DIR. Please check the script's directory structure." >&2
    exit 1
  fi
fi

# Load the config file if PROJECT_DIR is set
CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi

# Source the config file
source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/wordpress_loader.sh"

# === Parse command line flags ===
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --site_name=*)
      site_name="${1#*=}"
      shift
      ;;
    *)
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
done

# Ensure valid parameters are passed
if [ -z "$site_name" ]; then
  echo "❌ Missing required parameter: --site_name"
  exit 1
fi

# === Call the logic function to reset user role ===
reset_user_role_logic "$site_name"
