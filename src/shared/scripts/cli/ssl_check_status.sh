#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script Name: ssl_check_status.sh
# Description: This script checks the SSL certificate status for a given site.
#              It ensures the script is run in a Bash shell, determines the
#              project directory, loads necessary configurations, and validates
#              SSL certificates using a logic function.
#
# Usage:
#   ./ssl_check_status.sh --site_name=<site_name> [--ssl_dir=<ssl_directory>]
#
# Arguments:
#   --site_name   (Required) The name of the site for which to check the SSL status.
#   --ssl_dir     (Optional) The directory containing SSL certificates. Defaults
#                 to "$PROJECT_DIR/shared/ssl" if not provided.
#
# Requirements:
#   - The script must be executed in a Bash shell.
#   - The environment variable PROJECT_DIR must be set, or the script must be
#     located within a directory structure containing 'shared/config/config.sh'.
#   - The configuration file 'config.sh' must exist in the expected location.
#   - The 'ssl_loader.sh' script must be available in the FUNCTIONS_DIR.
#
# Exit Codes:
#   1 - If the script is not run in a Bash shell.
#   1 - If PROJECT_DIR cannot be determined.
#   1 - If the configuration file is not found.
#   1 - If the required --site_name parameter is missing.
#
# Example:
#   ./ssl_check_status.sh --site_name=mywebsite --ssl_dir=/path/to/ssl
#
# -----------------------------------------------------------------------------

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
source "$FUNCTIONS_DIR/ssl_loader.sh"

# === Parse arguments ===
for arg in "$@"; do
  case $arg in
    --site_name=*) SITE_NAME="${arg#*=}" ;;
    --ssl_dir=*) SSL_DIR="${arg#*=}" ;;
  esac
done

# === Check if site_name is provided ===
if [[ -z "$SITE_NAME" ]]; then
  echo "❌ Missing required --site_name parameter"
  exit 1
fi

# === Set default SSL_DIR if not provided ===
if [[ -z "$SSL_DIR" ]]; then
  SSL_DIR="$PROJECT_DIR/shared/ssl"
fi

# === Check SSL certificate status using the logic function ===
ssl_check_certificate_status_logic "$SITE_NAME" "$SSL_DIR"