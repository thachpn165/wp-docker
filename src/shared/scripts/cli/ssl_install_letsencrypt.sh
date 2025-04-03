#!/usr/bin/env bash
# This script installs Let's Encrypt SSL certificates for a specified site.
# It ensures the script is run in a Bash shell, validates required environment variables,
# parses input arguments, and invokes the SSL installation logic.

# Prerequisites:
# - The script must be executed in a Bash shell.
# - The PROJECT_DIR environment variable must be set or determinable from the script's directory structure.
# - A valid configuration file (config.sh) must exist in the expected directory structure.
# - The ssl_loader.sh script must be available in the FUNCTIONS_DIR.

# Input Arguments:
# --site_name=<site_name> : (Required) The name of the site for which the SSL certificate will be installed.
# --email=<email>         : (Required) The email address to be used for Let's Encrypt registration.
# --staging               : (Optional) If provided, the script will use Let's Encrypt's staging environment.

# Behavior:
# - Validates that the script is run in a Bash shell.
# - Determines the PROJECT_DIR by searching for the config.sh file in the script's directory structure.
# - Loads the configuration and required functions from the specified files.
# - Parses input arguments to extract the site name, email, and optional staging flag.
# - Ensures that the required parameters (--site_name and --email) are provided.
# - Invokes the `ssl_install_lets_encrypt_logic` function to handle the SSL installation process.

# Error Handling:
# - Exits with an error message if the script is not run in a Bash shell.
# - Exits with an error message if the PROJECT_DIR cannot be determined or the config file is missing.
# - Exits with an error message if required parameters (--site_name or --email) are not provided.

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
source "$FUNCTIONS_DIR/ssl_loader.sh"

# === Parse input arguments ===
for arg in "$@"; do
  case $arg in
    --site_name=*) SITE_NAME="${arg#*=}" ;;
    --email=*) EMAIL="${arg#*=}" ;;
    --staging) STAGING=true ;;
  esac
done

# Ensure site_name and email are provided
if [[ -z "$SITE_NAME" || -z "$EMAIL" ]]; then
  echo "${CROSSMARK} Missing required parameters: --site_name and --email are required."
  exit 1
fi

# Call the logic to install Let's Encrypt SSL
ssl_install_lets_encrypt_logic "$SITE_NAME" "$EMAIL" "$STAGING"