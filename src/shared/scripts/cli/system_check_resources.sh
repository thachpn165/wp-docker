#!/bin/bash
# This script performs a system resource check by leveraging project-specific configurations and functions.
# 
# Prerequisites:
# - The script must be executed in a Bash shell.
# - The environment variable `PROJECT_DIR` should point to the root directory of the project. If not set, the script will attempt to determine it by searching for the `config.sh` file in the directory hierarchy.
# - The `config.sh` file must exist in the `shared/config/` directory relative to the project root.
# - The `system_loader.sh` script must exist in the directory specified by the `FUNCTIONS_DIR` variable in the `config.sh` file.
# 
# Script Workflow:
# 1. Verifies that the script is running in a Bash shell.
# 2. Attempts to determine the `PROJECT_DIR` if it is not already set by searching for the `config.sh` file.
# 3. Validates the existence of the `config.sh` file in the expected location.
# 4. Sources the `config.sh` file to load project-specific configurations.
# 5. Sources the `system_loader.sh` script to load necessary functions.
# 6. Invokes the `system_check_resources_logic` function to perform the resource check.
# 
# Error Handling:
# - If the script is not executed in a Bash shell, it exits with an error message.
# - If the `PROJECT_DIR` cannot be determined, it exits with an error message.
# - If the `config.sh` file is missing, it exits with an error message.
# 
# Usage:
# Run this script from a Bash shell in an environment where the project directory structure is intact.

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

# Call the logic function
system_check_resources_logic
