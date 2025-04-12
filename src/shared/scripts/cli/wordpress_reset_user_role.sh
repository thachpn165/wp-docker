#!/bin/bash
# -----------------------------------------------------------------------------
# Script Name: wordpress_reset_user_role.sh
# Description: This script resets the user role for a specified WordPress site.
#              It ensures the script is run in a Bash shell, determines the 
#              project directory, loads the necessary configuration, and 
#              executes the logic to reset the user role.
#
# Usage:
#   ./wordpress_reset_user_role.sh --domain=example.tld
#
# Parameters:
#   --domain=example.tld : (Required) The name of the WordPress site for 
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
#   ./wordpress_reset_user_role.sh --domain=my_wordpress_site
#
# -----------------------------------------------------------------------------
# ✅ Load configuration from any directory
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
SEARCH_PATH="$SCRIPT_PATH"
while [[ "$SEARCH_PATH" != "/" ]]; do
  if [[ -f "$SEARCH_PATH/shared/config/load_config.sh" ]]; then
    source "$SEARCH_PATH/shared/config/load_config.sh"
    load_config_file
    break
  fi
  SEARCH_PATH="$(dirname "$SEARCH_PATH")"
done

# Load functions for website management
safe_source "$FUNCTIONS_DIR/wordpress_loader.sh"

# === Parse command line flags ===
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --domain=*)
      domain="${1#*=}"
      shift
      ;;
    *)
      #echo "Unknown parameter: $1"
      print_and_debug error "$ERROR_UNKNOW_PARAM: $1"
      exit 1
      ;;
  esac
done

# Ensure valid parameters are passed
if [ -z "$domain" ]; then
  print_and_debug error "$ERROR_MISSING_PARAM: --domain"
  exit 1
fi

# === Call the logic function to reset user role ===
reset_user_role_logic "$domain"
