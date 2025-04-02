#!/usr/bin/env bash
# This script generates a self-signed SSL certificate for a specified site.
#
# Prerequisites:
# - Must be executed in a Bash shell.
# - The environment variable PROJECT_DIR must be set or determinable from the script's directory structure.
# - A valid configuration file (config.sh) must exist in the shared/config directory relative to PROJECT_DIR.
# - The ssl_loader.sh script must be available in the FUNCTIONS_DIR directory.
#
# Usage:
#   ./ssl_generate_self_signed.sh --site_name=SITE_NAME
#
# Arguments:
#   --site_name=SITE_NAME  (Required) The name of the site for which the SSL certificate will be generated.
#
# Behavior:
# 1. Verifies that the script is running in a Bash shell.
# 2. Determines the PROJECT_DIR by searching upwards from the script's directory for the config.sh file.
# 3. Loads the configuration file (config.sh) and the SSL loader script (ssl_loader.sh).
# 4. Parses the --site_name argument to retrieve the site name.
# 5. Calls the `ssl_generate_self_signed_logic` function to generate the SSL certificate.
#
# Error Handling:
# - Exits with an error if not run in a Bash shell.
# - Exits with an error if PROJECT_DIR cannot be determined or the config.sh file is missing.
# - Exits with an error if the --site_name argument is not provided.

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

# === Parse argument ===
for arg in "$@"; do
  case $arg in
    --site_name=*) SITE_NAME="${arg#*=}" ;;
  esac
done

if [[ -z "$SITE_NAME" ]]; then
  echo "${CROSSMARK} Missing required --site_name=SITE_NAME parameter"
  exit 1
fi

# === Generate self-signed SSL ===
ssl_generate_self_signed_logic "$SITE_NAME"
