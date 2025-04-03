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
#   - website_management_create_logic: Handles the creation of the website.
#   - website_setup_wordpress_logic: Handles the setup of WordPress for the website.
#
# Example:
#   ./website_create.sh --domain=mywebsite.com --php=8.2 --auto_generate=true
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
source "$FUNCTIONS_DIR/website_loader.sh"

# === Input handling ===
auto_generate=true   # default: true
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --domain=*) domain="${1#*=}" ;;
    --php=*) php_version="${1#*=}" ;;
    --auto_generate=*) auto_generate="${1#*=}" ;;
    *) echo "❌ Unknown option: $1" ; exit 1 ;;
  esac
  shift
done
#if [[ -z "$site_name" || ]] 
if [[ -z "$domain" || -z "$php_version" ]]; then
  echo "❌ Missing parameters. Usage:"
  echo "  $0 --domain=abc.com --php=8.2"
  exit 1
fi

website_management_create_logic "$domain" "$php_version"
website_setup_wordpress_logic "$domain" "$auto_generate"

echo "✅ DONE_CREATE_WEBSITE: $domain"