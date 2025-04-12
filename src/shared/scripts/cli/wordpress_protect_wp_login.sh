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
# --domain=example.tld : (Required) The name of the WordPress site to apply the action to.
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
# - Exits with an error if required parameters (--domain and --action) are not provided.

# === Usage Example ===
# ./wordpress_protect_wp_login.sh --domain=mywebsite --action=enable
# This example enables protection for the wp-login.php page of the 'mywebsite' WordPress site.

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
safe_source "$FUNCTIONS_DIR/wordpress_loader.sh"

# === Parse command line flags ===
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --domain=*)
      domain="${1#*=}"
      shift
      ;;
    --action=*)
      action="${1#*=}"
      shift
      ;;
    *)
      print_and_debug error "$ERROR_UNKNOW_PARAM: $1"
      exit 1
      ;;
  esac
done

# Ensure valid parameters are passed
if [ -z "$domain" ] || [ -z "$action" ]; then
  print_and_debug error "$ERROR_MISSING_PARAM: --domain and --action"
  exit 1
fi

# === Call the logic function to protect wp-login ===
wordpress_protect_wp_login_logic "$domain" "$action"
