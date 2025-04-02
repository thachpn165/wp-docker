#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script Name: website_setup_wordpress.sh
# Description: This script sets up a WordPress website by sourcing configuration
#              files, parsing input arguments, and invoking the WordPress setup
#              logic function.
#
# Prerequisites:
#   - Must be run in a Bash shell.
#   - The environment variable PROJECT_DIR must be set or determinable from the
#     script's directory structure.
#   - The configuration file (config.sh) must exist in the expected directory.
#   - Required functions must be available in the FUNCTIONS_DIR.
#
# Usage:
#   ./website_setup_wordpress.sh --site_name=SITE --user=USER --pass=PASS --email=EMAIL
#
# Arguments:
#   --site_name=SITE   The name of the WordPress site to set up.
#   --user=USER        The admin username for the WordPress site.
#   --pass=PASS        The admin password for the WordPress site.
#   --email=EMAIL      The admin email address for the WordPress site.
#
# Exit Codes:
#   1 - If the script is not run in a Bash shell.
#   1 - If PROJECT_DIR cannot be determined.
#   1 - If the configuration file is not found.
#   1 - If required arguments are missing.
#
# Notes:
#   - The script iterates upwards from its directory to locate the configuration
#     file if PROJECT_DIR is not explicitly set.
#   - The script sources the configuration file and required function scripts
#     before executing the WordPress setup logic.
#
# Example:
#   ./website_setup_wordpress.sh --site_name=mywebsite --user=admin --pass=secret --email=admin@example.com
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

# === Parse arguments ===
for arg in "$@"; do
  case $arg in
    --site_name=*) site_name="${arg#*=}" ;;
    --user=*) admin_user="${arg#*=}" ;;
    --pass=*) admin_password="${arg#*=}" ;;
    --email=*) admin_email="${arg#*=}" ;;
  esac
done

# === Check required ===
if [[ -z "$site_name" || -z "$admin_user" || -z "$admin_password" || -z "$admin_email" ]]; then
  echo "${CROSSMARK} Missing required parameters."
  echo "Usage: $0 --site_name=SITE --user=USER --pass=PASS --email=EMAIL"
  exit 1
fi

# === Call function === 
source "$FUNCTIONS_DIR/website/website_setup_wordpress.sh"
website_setup_wordpress_logic "$site_name" "$admin_user" "$admin_password" "$admin_email"
