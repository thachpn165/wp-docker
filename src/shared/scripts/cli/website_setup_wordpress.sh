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
#   ./website_setup_wordpress.sh --domain=DOMAIN --user=USER --pass=PASS --email=EMAIL
#
# Arguments:
#   --domain=DOMAIN   The domain of the WordPress site to set up.
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
#   ./website_setup_wordpress.sh --domain=mywebsite.com --user=admin --pass=secret --email=admin@example.com
# -----------------------------------------------------------------------------

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
source "$FUNCTIONS_DIR/website_loader.sh"

# === Parse arguments ===
for arg in "$@"; do
  case $arg in
    --domain=*) domain="${arg#*=}" ;;
    --user=*) admin_user="${arg#*=}" ;;
    --pass=*) admin_password="${arg#*=}" ;;
    --email=*) admin_email="${arg#*=}" ;;
  esac
done

# === Check required ===
if [[ -z "$domain" || -z "$admin_user" || -z "$admin_password" || -z "$admin_email" ]]; then
  #echo "${CROSSMARK} Missing required parameters."
  print_and_debug error "$ERROR_MISSING_PARAM: --domain, --user, --pass, --email"
  
  exit 1
fi

# === Call function === 
source "$FUNCTIONS_DIR/website/website_setup_wordpress.sh"
website_setup_wordpress_logic "$domain" "$admin_user" "$admin_password" "$admin_email"
