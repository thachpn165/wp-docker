#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script Name: website_delete.sh
# Description: This script deletes a website by invoking the appropriate 
#              deletion logic. It ensures the script is run in a Bash shell, 
#              validates the environment, and sources necessary configuration 
#              and function files before executing the deletion logic.
#
# Usage:
#   ./website_delete.sh --domain=DOMAIN
#
# Arguments:
#   --domain=DOMAIN   The domain of the site to be deleted. This parameter 
#                     is required.
#
# Environment Variables:
#   PROJECT_DIR             The root directory of the project. If not set, the 
#                           script attempts to determine it by traversing the 
#                           directory structure to locate 'config.sh'.
#
# Requirements:
#   - The script must be executed in a Bash shell.
#   - The 'config.sh' file must exist in the shared/config directory relative 
#     to the project root.
#   - The 'website_loader.sh' script must exist in the FUNCTIONS_DIR directory.
#
# Exit Codes:
#   1  If the script is not run in a Bash shell.
#   1  If PROJECT_DIR cannot be determined.
#   1  If the config file is not found.
#   1  If the --domain parameter is missing.
#
# Notes:
#   - The script sources the 'config.sh' file to load environment variables 
#     and configurations.
#   - The 'website_loader.sh' script is sourced to load the 
#     `website_management_delete_logic` function.
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
source "$FUNCTIONS_DIR/website_loader.sh"

# === Parse argument ===
domain=""
backup_enabled="false"
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --domain=*) domain="${1#*=}" ;;
    --backup_enabled=*) backup_enabled="${1#*=}" ;;
    *)
      print_and_debug error "$ERROR_UNKNOW_PARAM: $1"
      exit 1
      ;;
  esac
  shift
done

if [[ -z "$domain" ]]; then
  print_msg error "$ERROR_MISSING_PARAM: --domain"
  exit 1
fi

# === Run deletion logic ===
website_management_delete_logic "$domain" "$backup_enabled"
