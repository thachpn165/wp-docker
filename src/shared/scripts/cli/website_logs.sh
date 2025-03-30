#!/usr/bin/env bash

# ==========================================
# 🗂️ website_logs.sh – Fetch logs for a WordPress Website
# ==========================================

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
source "$FUNCTIONS_DIR/website_loader.sh"

# === Parse argument for --site_name and --log_type ===
for arg in "$@"; do
  case $arg in
    --site_name=*) SITE_NAME="${arg#*=}" ;;  # Ensure it's SITE_NAME
    --log_type=*) LOG_TYPE="${arg#*=}" ;;
  esac
done
# Check if SITE_NAME is set
if [[ -z "$SITE_NAME" ]]; then
  echo "❌ site_name is not set. Please provide a valid site name."
  exit 1
fi

# Check if LOG_TYPE is set and valid
if [[ -z "$LOG_TYPE" || ! "$LOG_TYPE" =~ ^(access|error)$ ]]; then
  echo "❌ log_type is required. Please specify access or error log."
  exit 1
fi

# === Call the website management logic to show the logs ===
website_management_logs "$SITE_NAME" "$LOG_TYPE"