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

# 🔧 Auto-detect BASE_DIR and load global configuration
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
  if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
    source "$SCRIPT_PATH/shared/config/load_config.sh"
    break
  fi
  SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done
source "$FUNCTIONS_DIR/system_loader.sh"

# === Call the logic function to clean up Docker system ===
system_cleanup_docker_logic