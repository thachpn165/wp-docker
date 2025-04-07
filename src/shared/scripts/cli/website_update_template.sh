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

# Parse arguments
for arg in "$@"; do
  case $arg in
    --domain=*) domain="${arg#*=}" ;;
  esac
done

if [[ -z "$domain" ]]; then
  print_and_debug error "$ERROR_MISSING_PARAM: --domain"
  exit 1
fi

# Call the logic to update sites
website_management_update_site_template_logic "$domain"