#!/bin/bash
# This script is used to manage WordPress plugin auto-update settings for a specific site.
# It requires a Bash shell to execute and depends on a specific directory structure and configuration file.

# Prerequisites:
# - The script must be executed in a Bash shell.
# - The environment variable PROJECT_DIR must either be set or determinable by the script.
# - A configuration file (config.sh) must exist in the shared/config directory relative to PROJECT_DIR.
# - The script depends on functions defined in wordpress_loader.sh.

# Usage:
# ./wordpress_auto_update_plugin.sh --domain=example.tld --action=<action>
# 
# Parameters:
# --domain=example.tld  : The name of the WordPress site for which the plugin auto-update settings will be managed.
# --action=<action>        : The action to perform on the plugin auto-update settings (e.g., enable, disable).

# Behavior:
# 1. Validates that the script is running in a Bash shell.
# 2. Determines the PROJECT_DIR by searching for the config.sh file in the directory hierarchy.
# 3. Loads the configuration file and required functions.
# 4. Parses command-line arguments to extract the site name and action.
# 5. Validates that the required parameters are provided.
# 6. Calls the `wordpress_auto_update_plugin_logic` function to perform the specified action.

# Error Handling:
# - If the script is not run in a Bash shell, it exits with an error.
# - If PROJECT_DIR cannot be determined or the config file is missing, the script exits with an error.
# - If required parameters (--domain and --action) are not provided, the script exits with an error.
# - If an unknown parameter is passed, the script exits with an error.

# Example:
# ./wordpress_auto_update_plugin.sh --domain=mywebsite --action=enable
# This command enables auto-updates for plugins on the WordPress site named "mywebsite".

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
if [ -z "$domain" ] || [ -z "$action" ]; then
  echo "${CROSSMARK} Missing required parameters: --domain and --action"
  exit 1
fi

# === Call the logic function to update plugin auto-update settings ===
wordpress_auto_update_plugin_logic "$domain" "$action"
