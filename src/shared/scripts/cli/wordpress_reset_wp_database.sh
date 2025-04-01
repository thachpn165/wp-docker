#!/bin/bash
# This script resets the WordPress database for a specified site.
#
# Prerequisites:
# - The script must be executed in a Bash shell.
# - The environment variable `PROJECT_DIR` must be set or determinable from the script's directory structure.
# - The configuration file `config.sh` must exist in the `shared/config` directory within the project structure.
# - The `wordpress_loader.sh` script must be available in the directory specified by the `FUNCTIONS_DIR` variable.
#
# Usage:
#   ./wordpress_reset_wp_database.sh --site_name=<site_name>
#
# Parameters:
#   --site_name=<site_name> : (Required) The name of the WordPress site whose database will be reset.
#
# Behavior:
# - Validates that the script is run in a Bash shell.
# - Determines the `PROJECT_DIR` by searching for the `config.sh` file in the script's directory hierarchy.
# - Sources the `config.sh` configuration file and the `wordpress_loader.sh` script.
# - Parses the `--site_name` parameter from the command line arguments.
# - Calls the `wordpress_reset_wp_database_logic` function to reset the database for the specified site.
#
# Error Handling:
# - Exits with an error message if the script is not run in a Bash shell.
# - Exits with an error message if `PROJECT_DIR` cannot be determined.
# - Exits with an error message if the `config.sh` file is missing.
# - Exits with an error message if the required `--site_name` parameter is not provided.
# - Exits with an error message for unknown command-line parameters.
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
source "$FUNCTIONS_DIR/wordpress_loader.sh"

# === Parse command line flags ===
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --site_name=*)
      site_name="${1#*=}"
      shift
      ;;
    *)
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
done

# Ensure valid parameters are passed
if [ -z "$site_name" ]; then
  echo "❌ Missing required parameter: --site_name"
  exit 1
fi

# === Call the logic function to reset WordPress database ===
wordpress_reset_wp_database_logic "$site_name"
