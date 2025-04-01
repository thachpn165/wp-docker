# This script performs a Docker system cleanup by invoking a predefined logic function.
# It ensures the script is executed in a Bash shell and verifies the required environment
# variables and configuration files are properly set up before proceeding.
#
# Functionality:
# 1. Ensures the script is run in a Bash shell.
# 2. Determines the PROJECT_DIR by traversing upwards from the script's directory
#    to locate the 'config.sh' file.
# 3. Validates the presence of the configuration file and sources it.
# 4. Sources additional required scripts, such as 'system_loader.sh'.
# 5. Invokes the `system_cleanup_docker_logic` function to perform the cleanup.
#
# Prerequisites:
# - The script must be executed in a Bash shell.
# - The environment variable `PROJECT_DIR` must either be set or determinable
#   by the script's directory structure.
# - The configuration file (`config.sh`) must exist in the expected location.
# - The `system_loader.sh` script must be present in the `$FUNCTIONS_DIR` directory.
#
# Error Handling:
# - Exits with an error message if the script is not run in a Bash shell.
# - Exits with an error message if `PROJECT_DIR` cannot be determined.
# - Exits with an error message if the configuration file is missing.
#
# Usage:
# Run this script directly in a Bash shell. Ensure the required directory structure
# and configuration files are in place before execution.
#!/bin/bash
if [ -z "$BASH_VERSION" ]; then
  echo "❌ This script must be run in a Bash shell." >&2
  exit 1
fi

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
source "$FUNCTIONS_DIR/system_loader.sh"

# === Call the logic function to clean up Docker system ===
system_cleanup_docker_logic