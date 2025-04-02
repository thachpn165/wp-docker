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
#!/usr/bin/env bash

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
source "$FUNCTIONS_DIR/website_loader.sh"

website_management_list
