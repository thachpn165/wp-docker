#!/usr/bin/env bash

# This script lists websites managed by the project.
#
# Prerequisites:
# - The script must be executed in a Bash shell.
# - The environment variable PROJECT_DIR must be set, or the script will attempt to determine it
#   by searching for 'config.sh' in the directory structure.
# - The 'config.sh' file must exist in the expected location within the project directory.
# - The 'website_loader.sh' script must be present in the FUNCTIONS_DIR directory.
#
# Behavior:
# - If not executed in a Bash shell, the script will terminate with an error message.
# - If PROJECT_DIR is not set, the script will search for 'config.sh' by traversing upwards
#   from the script's directory.
# - If 'config.sh' is not found, the script will terminate with an error message.
# - The script sources the 'config.sh' file and the 'website_loader.sh' script.
# - The `website_management_list` function is called to list the websites.
#
# Error Handling:
# - The script exits with an error message if:
#   - It is not run in a Bash shell.
#   - PROJECT_DIR cannot be determined.
#   - The 'config.sh' file is missing.

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

website_management_list
