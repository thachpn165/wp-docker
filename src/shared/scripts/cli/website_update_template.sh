#!/bin/bash
# This script updates the template for a specified website in a project.
#
# Prerequisites:
# - The script must be executed in a Bash shell.
# - The environment variable PROJECT_DIR must be set, or the script must be located
#   within a directory structure containing 'shared/config/config.sh'.
#
# Environment Variables:
# - PROJECT_DIR: The root directory of the project. If not set, the script will attempt
#   to determine it by searching upwards from the script's directory for 'shared/config/config.sh'.
# - FUNCTIONS_DIR: Directory containing additional function scripts, such as 'website_loader.sh'.
#
# Arguments:
# - --domain=SITE_DOMAIN: (Required) The name of the site to update the template for.
#
# Behavior:
# 1. Ensures the script is run in a Bash shell.
# 2. Determines the PROJECT_DIR if not already set by searching for 'config.sh'.
# 3. Loads the configuration file located at "$PROJECT_DIR/shared/config/config.sh".
# 4. Sources additional functions from "$FUNCTIONS_DIR/website_loader.sh".
# 5. Parses the --domain argument to identify the target site.
# 6. Invokes the `website_management_update_site_template_logic` function with the specified site name.
#
# Error Handling:
# - Exits with an error message if:
#   - The script is not run in a Bash shell.
#   - PROJECT_DIR cannot be determined.
#   - The configuration file is missing.
#   - The required --domain argument is not provided.

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

# Parse arguments
for arg in "$@"; do
  case $arg in
    --domain=*) domain="${arg#*=}" ;;
  esac
done

if [[ -z "$domain" ]]; then
  echo "${CROSSMARK} Missing required --domain=SITE_DOMAIN parameter"
  exit 1
fi

# Call the logic to update sites
website_management_update_site_template_logic "$domain"