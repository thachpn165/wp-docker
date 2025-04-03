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
#   ./website_logs.sh --site_name=<site_name> --log_type=<log_type>
#
# Arguments:
#   --site_name=<site_name>  The name of the website for which logs are to be retrieved.
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
#   ./website_logs.sh --site_name=mywebsite --log_type=access
#   ./website_logs.sh --site_name=mywebsite --log_type=error
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

# === Parse argument for --site_name and --log_type ===
for arg in "$@"; do
  case $arg in
    --site_name=*) SITE_NAME="${arg#*=}" ;;  # Ensure it's SITE_NAME
    --log_type=*) LOG_TYPE="${arg#*=}" ;;
  esac
done
# Check if SITE_NAME is set
if [[ -z "$SITE_NAME" ]]; then
  echo "${CROSSMARK} site_name is not set. Please provide a valid site name."
  exit 1
fi

# Check if LOG_TYPE is set and valid
if [[ -z "$LOG_TYPE" || ! "$LOG_TYPE" =~ ^(access|error)$ ]]; then
  echo "${CROSSMARK} log_type is required. Please specify access or error log."
  exit 1
fi

# === Call the website management logic to show the logs ===
website_management_logs "$SITE_NAME" "$LOG_TYPE"