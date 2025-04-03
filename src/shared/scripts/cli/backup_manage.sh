#!/bin/bash

# This script is used to manage backups for a specified site. It loads the necessary configuration
# and utility functions, parses command-line arguments, and invokes the `backup_manage` function
# with the provided parameters.

# === Script Overview ===
# - Loads configuration and utility scripts required for backup management.
# - Parses command-line arguments to extract parameters such as site name, action, and optional max age.
# - Validates the required parameters and ensures they are provided.
# - Executes the `backup_manage` function with the parsed parameters.

# === Command-Line Arguments ===
# --domain=<site_name>   : (Required) The name of the site for which the backup action is to be performed.
# --action=<action>         : (Required) The action to perform (e.g., create, restore, delete).
# --max_age_days=<days>     : (Optional) The maximum age of backups to consider, in days.

# === Exit Codes ===
# 0  : Success.
# 1  : Failure due to missing configuration file, invalid parameters, or unknown arguments.

# === Example Usage ===
# ./backup_manage.sh --domain=my_site --action=create
# ./backup_manage.sh --domain=my_site --action=delete --max_age_days=30

# === Load config & backup_utils.sh ===

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
    --domain=*)
      domain="${1#*=}"
      shift
      ;;
    --action=*)
      action="${1#*=}"
      shift
      ;;
    --max_age_days=*)
      max_age_days="${1#*=}"
      shift
      ;;
    *)
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
done

# Ensure valid parameters are passed
if [[ -z "$domain" || -z "$action" ]]; then
  echo "${CROSSMARK} Missing required parameters. Ensure --domain and --action are provided."
  exit 1
fi

# Call the backup_manage function with the passed parameters
backup_manage "$domain" "$action" "$max_age_days"
