#!/usr/bin/env bash

# ============================================
# ✅ Install Let's Encrypt SSL Certificate
# ============================================

# === Load configuration and logic ===
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

CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi
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
  echo "❌ Missing required parameters: --site_name and --email are required."
  exit 1
fi

# Call the logic to install Let's Encrypt SSL
ssl_install_lets_encrypt_logic "$SITE_NAME" "$EMAIL" "$STAGING"