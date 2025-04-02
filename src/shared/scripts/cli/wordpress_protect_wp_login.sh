#!/bin/bash
# This script is used to protect the WordPress wp-login.php page by applying specific actions
# based on the provided parameters. It ensures the script is executed in a Bash shell, validates
# the required environment variables and configuration files, and processes command-line arguments.

# === Script Overview ===
# - Ensures the script is run in a Bash shell.
# - Determines the PROJECT_DIR by locating the 'config.sh' file in the directory structure.
# - Loads the configuration file and required functions.
# - Parses command-line arguments to extract the site name and action.
# - Invokes the logic function to apply the specified action to the WordPress wp-login.php page.

# === Command-Line Parameters ===
# --site_name=<site_name> : (Required) The name of the WordPress site to apply the action to.
# --action=<action>       : (Required) The action to perform (e.g., enable or disable protection).

# === Environment Variables ===
# PROJECT_DIR : The root directory of the project, determined dynamically if not set.
# FUNCTIONS_DIR : Directory containing helper functions, expected to be defined in the config file.

# === Dependencies ===
# - The script requires a valid 'config.sh' file in the shared/config directory.
# - The 'wordpress_loader.sh' script must be available in the FUNCTIONS_DIR.

# === Error Handling ===
# - Exits with an error if the script is not run in a Bash shell.
# - Exits with an error if PROJECT_DIR cannot be determined or the config file is missing.
# - Exits with an error if required parameters (--site_name and --action) are not provided.

# === Usage Example ===
# ./wordpress_protect_wp_login.sh --site_name=mywebsite --action=enable
# This example enables protection for the wp-login.php page of the 'mywebsite' WordPress site.

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
    --action=*)
      action="${1#*=}"
      shift
      ;;
    *)
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
done

# Ensure valid parameters are passed
if [ -z "$site_name" ] || [ -z "$action" ]; then
  echo "❌ Missing required parameters: --site_name and --action"
  exit 1
fi

# === Call the logic function to protect wp-login ===
wordpress_protect_wp_login_logic "$site_name" "$action"
