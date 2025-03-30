#!/usr/bin/env bash

# === Auto-detect PROJECT_DIR ===
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

# === Load config & logic ===
CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi
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
  echo "❌ Missing required parameters."
  echo "Usage: $0 --site_name=SITE --user=USER --pass=PASS --email=EMAIL"
  exit 1
fi

# === Call function ===
source "$FUNCTIONS_DIR/website/website_setup_wordpress.sh"
website_setup_wordpress_logic "$site_name" "$admin_user" "$admin_password" "$admin_email"
