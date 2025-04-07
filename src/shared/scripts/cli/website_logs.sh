#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script Name: website_logs.sh
# Description: This script retrieves and displays the logs (access or error) 
#              for a specified website in a Docker-based LEMP stack environment.
#
# Prerequisites:
#   - Must be run in a Bash shell.
#   - The environment variable PROJECT_DIR must be set or determinable from the
#     script's directory structure.
#   - A valid configuration file (config.sh) must exist in the shared/config 
#     directory relative to PROJECT_DIR.
#
# Usage:
#   ./website_logs.sh --domain=example.tld --log_type=<log_type>
#
# Arguments:
#   --domain=example.tld  The name of the website for which logs are to be retrieved.
#   --log_type=<log_type>    The type of log to retrieve. Must be either "access" or "error".
#
# Exit Codes:
#   1  - Script is not run in a Bash shell.
#   1  - PROJECT_DIR cannot be determined or is not set.
#   1  - Configuration file (config.sh) is not found.
#   1  - site_name argument is not provided.
#   1  - log_type argument is not provided or is invalid.
#
# Dependencies:
#   - The script sources the following files:
#       - config.sh: Contains configuration variables.
#       - website_loader.sh: Contains functions for website management.
#
# Notes:
#   - The script attempts to determine PROJECT_DIR by traversing upwards from 
#     the script's directory to locate the config.sh file.
#   - The website_management_logs function is called to handle the log retrieval.
#
# Examples:
#   ./website_logs.sh --domain=mywebsite --log_type=access
#   ./website_logs.sh --domain=mywebsite --log_type=error
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

# === Parse argument for --domain and --log_type ===
for arg in "$@"; do
  case $arg in
    --domain=*) domain="${arg#*=}" ;;  # Ensure it's SITE_DOMAIN
    --log_type=*) LOG_TYPE="${arg#*=}" ;;
  esac
done
# Check if SITE_DOMAIN is set
if [[ -z "$domain" ]]; then
  #echo "${CROSSMARK} site_name is not set. Please provide a valid site name."
  print_and_debug error "$ERROR_MISSING_PARAM: --domain"
  print_msg info "$INFO_PARAM_EXAMPLE:\n  --domain=example.tld"
  exit 1
fi

# Check if LOG_TYPE is set and valid
if [[ -z "$LOG_TYPE" || ! "$LOG_TYPE" =~ ^(access|error)$ ]]; then
  #echo "${CROSSMARK} log_type is required. Please specify access or error log."
  print_and_debug error "$ERROR_MISSING_PARAM: --log_type"
  print_msg info "$INFO_PARAM_EXAMPLE:\n  --log_type=access\n  --log_type=error"
  exit 1
fi

# === Call the website management logic to show the logs ===
website_management_logs "$domain" "$LOG_TYPE"