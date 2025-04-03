# This script provides information about a specific website by utilizing the 
# `website_management_info_logic` function. It requires the `--domain` 
# parameter to specify the target website.

# Prerequisites:
# - The script must be executed in a Bash shell.
# - The environment variable `PROJECT_DIR` must either be set or determinable 
#   by locating the `config.sh` file in the directory structure.
# - The `config.sh` file must exist in the `$PROJECT_DIR/shared/config/` directory.
# - The `website_loader.sh` script must exist in the `$FUNCTIONS_DIR` directory.

# Script Workflow:
# 1. Verifies that the script is running in a Bash shell.
# 2. Attempts to determine the `PROJECT_DIR` by searching for the `config.sh` 
#    file in the directory hierarchy if `PROJECT_DIR` is not already set.
# 3. Ensures the `config.sh` file exists and sources it along with the 
#    `website_loader.sh` script.
# 4. Parses the `--domain` parameter from the command-line arguments.
# 5. Validates that the `--domain` parameter is provided.
# 6. Calls the `website_management_info_logic` function with the provided 
#    `site_name` to display the website information.

# Usage:
#   ./website_info.sh --domain=<site_name>

# Parameters:
#   --domain=<site_name> : (Required) The name of the website for which 
#                             information is to be displayed.

# Error Handling:
# - Exits with an error message if:
#   - The script is not run in a Bash shell.
#   - The `PROJECT_DIR` cannot be determined.
#   - The `config.sh` file is missing.
#   - An unknown parameter is provided.
#   - The `--domain` parameter is missing.
#!/usr/bin/env bash

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
source "$FUNCTIONS_DIR/website_loader.sh"

# === Parse argument for site_name ===
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --domain=*) domain="${1#*=}" ;;
    *) echo "${CROSSMARK} Unknown parameter: $1"; exit 1 ;;
  esac
  shift
done

# === Ensure site_name is provided ===
if [[ -z "$domain" ]]; then
  echo "${CROSSMARK} Missing required --domain parameter"
  exit 1
fi

# === Call logic to display website information ===
website_management_info_logic "$domain"
