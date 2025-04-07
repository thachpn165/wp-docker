#!/bin/bash
# This script resets the WordPress admin password for a specified site and user.
#
# Prerequisites:
# - The script must be executed in a Bash shell.
# - The environment variable PROJECT_DIR must be set or determinable from the script's directory structure.
# - A valid configuration file (config.sh) must exist in the shared/config directory within the project structure.
# - The `wordpress_loader.sh` script must be available in the FUNCTIONS_DIR directory.
#
# Usage:
#   ./wordpress_reset_admin_passwd.sh --domain=example.tld --user_id=<user_id>
#
# Parameters:
#   --domain=example.tld  The name of the WordPress site for which the admin password will be reset.
#   --user_id=<user_id>      The ID of the user whose password will be reset.
#
# Behavior:
# - Validates that the script is run in a Bash shell.
# - Determines the PROJECT_DIR by searching for the config.sh file in the directory structure.
# - Sources the configuration file and WordPress loader script.
# - Parses the command-line arguments to extract the site name and user ID.
# - Ensures that the required parameters (--domain and --user_id) are provided.
# - Calls the `reset_admin_password_logic` function to perform the password reset operation.
#
# Error Handling:
# - Exits with an error message if the script is not run in a Bash shell.
# - Exits with an error message if PROJECT_DIR cannot be determined or the config file is missing.
# - Exits with an error message if required parameters are not provided or unknown parameters are passed.

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
source "$FUNCTIONS_DIR/wordpress_loader.sh"
# === Parse command line flags ===
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --domain=*)
      domain="${1#*=}"
      shift
      ;;
    --user_id=*)
      user_id="${1#*=}"
      shift
      ;;
    *)
      print_and_debug error "$ERROR_UNKNOW_PARAM: $1"
      exit 1
      ;;
  esac
done

# Ensure valid parameters are passed
if [ -z "$domain" ] || [ -z "$user_id" ]; then
  print_and_debug error "$ERROR_MISSING_PARAM: --domain and --user_id"
  exit 1
fi

# === Call the logic function to reset admin password ===
reset_admin_password_logic "$domain" "$user_id"