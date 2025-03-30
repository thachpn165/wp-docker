#!/usr/bin/env bash

# ============================================
# 📝 cli/website_info.sh – Show Website Information via CLI
# ============================================
# This script displays website information for a specified site name.
# It auto-detects the project directory, loads necessary configurations
# and functions, and invokes the logic to retrieve and display the website
# information.
#
# Usage:
#   ./website_info.sh --site_name=<site_name>
#
# Parameters:
#   --site_name=<site_name> : (Required) The name of the site for which
#                             information is to be displayed.
#
# Behavior:
# - Automatically detects the PROJECT_DIR if not already set.
# - Loads the configuration file and required helper scripts.
# - Validates the presence of the `--site_name` parameter.
# - Calls the `website_management_info_logic` function to display the
#   website information.
#
# Exit Codes:
#   0 : Success
#   1 : Failure due to missing configuration file or invalid parameters.
#
# Dependencies:
# - Requires the `config.sh` file located in the shared/config directory.
# - Requires helper scripts such as `website_loader.sh` and
#   `website_management_info.sh`.
#
# Example:
#   ./website_info.sh --site_name=mywebsite
# ============================================

# === Auto-detect PROJECT_DIR (source code root) ===
if [[ -z "$PROJECT_DIR" ]]; then
  SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
  while [[ "$SCRIPT_PATH" != "/" ]]; do
    if [[ -f "$SCRIPT_PATH/shared/config/config.sh" ]]; then
      PROJECT_DIR="$SCRIPT_PATH"
      break
    fi
    SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
  done
fi

# === Load config & website_loader.sh ===
CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi
source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/website_loader.sh"

# === Parse argument for site_name ===
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --site_name=*) site_name="${1#*=}" ;;
    *) echo "❌ Unknown parameter: $1"; exit 1 ;;
  esac
  shift
done

# === Ensure site_name is provided ===
if [[ -z "$site_name" ]]; then
  echo "❌ Missing required --site_name parameter"
  exit 1
fi

# === Call logic to display website information ===
website_management_info_logic "$site_name"
