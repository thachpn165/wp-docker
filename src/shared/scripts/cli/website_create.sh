#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script Name: website_create.sh
# Description: This script automates the creation of a website, including 
#              setting up the necessary configurations and optionally 
#              installing WordPress.
#
# Prerequisites:
#   - Must be run in a Bash shell.
#   - The environment variable PROJECT_DIR must be set or determinable from
#     the script's directory structure.
#   - A valid configuration file (config.sh) must exist in the shared/config
#     directory relative to PROJECT_DIR.
#
# Usage:
#   ./website_create.sh --domain=<domain> --php=<php_version> [--auto_generate=<true|false>]
#
# Options:
#   --domain=<domain>             Domain name for the website.
#   --php=<php_version>           PHP version to be used for the website.
#   --auto_generate=<true|false>  (Optional) Whether to auto-generate additional
#                                 configurations. Default is true.
#
# Exit Codes:
#   1 - Script not run in a Bash shell.
#   1 - PROJECT_DIR could not be determined.
#   1 - Config file not found.
#   1 - Missing required parameters or unknown options.
#
# Dependencies:
#   - The script sources the following files:
#       - $PROJECT_DIR/shared/config/config.sh
#       - $FUNCTIONS_DIR/website_loader.sh
#
# Functions:
#   - website_create_logic: Handles the creation of the website.
#   - website_setup_wordpress_logic: Handles the setup of WordPress for the website.
#
# Example:
#   ./website_create.sh --domain=mywebsite.com --php=8.2 --auto_generate=true
#
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

# === Input handling ===
auto_generate=true   # default: true
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --domain=*) domain="${1#*=}" ;;
    --php=*) php_version="${1#*=}" ;;
    --auto_generate=*) auto_generate="${1#*=}" ;;
    *)
      print_msg error "$ERROR_UNKNOW_PARAM: $1"
      print_msg info "$INFO_PARAM_EXAMPLE:\n  --domain=example.com --php=8.2"
      exit 1
      ;;
  esac
  shift
done
#if [[ -z "$domain" || ]] 
if [[ -z "$domain" || -z "$php_version" ]]; then
  #echo "${CROSSMARK} Missing parameters. Usage:"
  print_msg error "$ERROR_MISSING_PARAM: --domain & --php"
  exit 1
fi


website_create_logic "$domain" "$php_version"
website_setup_wordpress_logic "$domain" "$auto_generate"

## Debugging
debug_log "Domain: $domain"
debug_log "PHP Version: $php_version"
debug_log "Auto-generate: $auto_generate"
debug_log "Website creation process completed."
