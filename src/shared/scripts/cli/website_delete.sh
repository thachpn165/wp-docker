#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script Name: website_delete.sh
# Description: This script deletes a website by invoking the appropriate 
#              deletion logic. It ensures the script is run in a Bash shell, 
#              validates the environment, and sources necessary configuration 
#              and function files before executing the deletion logic.
#
# Usage:
#   ./website_delete.sh --site_name=SITE_NAME
#
# Arguments:
#   --site_name=SITE_NAME   The name of the site to be deleted. This parameter 
#                           is required.
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
#   1  If the --site_name parameter is missing.
#
# Notes:
#   - The script sources the 'config.sh' file to load environment variables 
#     and configurations.
#   - The 'website_loader.sh' script is sourced to load the 
#     `website_management_delete_logic` function.
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
source "$FUNCTIONS_DIR/website_loader.sh"

# === Parse argument ===
for arg in "$@"; do
  case $arg in
    --site_name=*) SITE_NAME="${arg#*=}" ;;
  esac
done

if [[ -z "$SITE_NAME" ]]; then
  echo "${CROSSMARK} Missing required --site_name=SITE_NAME parameter"
  exit 1
fi

# === Run deletion logic ===
website_management_delete_logic "$SITE_NAME"
