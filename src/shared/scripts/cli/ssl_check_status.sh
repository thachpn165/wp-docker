#!/usr/bin/env bash

# ============================================
# ✅ Check SSL Certificate Status for a Website
# ============================================

# === Load config & website_loader.sh ===
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