#!/bin/bash
# This script is used to rebuild the NGINX configuration for the project.
# It ensures that the script is executed in a Bash shell and verifies the
# presence of necessary environment variables and configuration files.
#
# Functionality:
# 1. Ensures the script is run in a Bash shell.
# 2. Determines the PROJECT_DIR by searching for the 'config.sh' file in the
#    directory hierarchy starting from the script's location.
# 3. Validates the existence of the configuration file 'config.sh' in the
#    expected location.
# 4. Sources the configuration file and additional required scripts.
# 5. Calls the `system_nginx_rebuild_logic` function to perform the rebuild.
#
# Prerequisites:
# - The script must be executed in a Bash shell.
# - The environment variable `PROJECT_DIR` must either be set or determinable
#   by locating the 'config.sh' file.
# - The configuration file 'config.sh' must exist in the expected directory
#   structure.
# - The `system_loader.sh` script must be present in the `$FUNCTIONS_DIR`.
#
# Usage:
# Run this script directly from the command line:
#   ./system_nginx_rebuild.sh
#
# Error Handling:
# - Exits with an error message if not run in a Bash shell.
# - Exits with an error message if `PROJECT_DIR` cannot be determined.
# - Exits with an error message if the configuration file is missing.

# 🔧 Auto-detect BASE_DIR and load global configuration
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
  if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
    source "$SCRIPT_PATH/shared/config/load_config.sh"
    break
  fi
  SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done
safe_source "$FUNCTIONS_DIR/system_loader.sh"

# === Call the logic function to rebuild NGINX ===
system_nginx_rebuild_logic
