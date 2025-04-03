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
#   ./wordpress_reset_admin_passwd.sh --domain=<site_name> --user_id=<user_id>
#
# Parameters:
#   --domain=<site_name>  The name of the WordPress site for which the admin password will be reset.
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
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
done

# Ensure valid parameters are passed
if [ -z "$domain" ] || [ -z "$user_id" ]; then
  echo "${CROSSMARK} Missing required parameters: --domain and --user_id"
  exit 1
fi

# === Call the logic function to reset admin password ===
reset_admin_password_logic "$domain" "$user_id"