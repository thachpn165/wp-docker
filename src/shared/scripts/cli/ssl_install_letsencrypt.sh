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
# --domain=example.tld : (Required) The name of the site for which the SSL certificate will be installed.
# --email=<email>         : (Required) The email address to be used for Let's Encrypt registration.
# --staging               : (Optional) If provided, the script will use Let's Encrypt's staging environment.

# Behavior:
# - Validates that the script is run in a Bash shell.
# - Determines the PROJECT_DIR by searching for the config.sh file in the script's directory structure.
# - Loads the configuration and required functions from the specified files.
# - Parses input arguments to extract the site name, email, and optional staging flag.
# - Ensures that the required parameters (--domain and --email) are provided.
# - Invokes the `ssl_install_lets_encrypt_logic` function to handle the SSL installation process.

# Error Handling:
# - Exits with an error message if the script is not run in a Bash shell.
# - Exits with an error message if the PROJECT_DIR cannot be determined or the config file is missing.
# - Exits with an error message if required parameters (--domain or --email) are not provided.

# 🔧 Auto-detect BASE_DIR and load global configuration
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
  if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
    source "$SCRIPT_PATH/shared/config/load_config.sh"
    break
  fi
  SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done
source "$FUNCTIONS_DIR/ssl_loader.sh"

# === Parse input arguments ===
for arg in "$@"; do
  case $arg in
    --domain=*) domain="${arg#*=}" ;;
    --email=*) EMAIL="${arg#*=}" ;;
    --staging) STAGING=true ;;
  esac
done

# Ensure domain and email are provided
if [[ -z "$domain" || -z "$EMAIL" ]]; then
  print_and_debug error "$ERROR_MISSING_PARAM: --domain and --email."
  exit 1
fi

# Call the logic to install Let's Encrypt SSL
ssl_install_lets_encrypt_logic "$domain" "$EMAIL" "$STAGING"