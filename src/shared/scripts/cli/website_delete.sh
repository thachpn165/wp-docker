#!/usr/bin/env bash

# ==========================================
# 🗑️ website_delete.sh – Delete a WordPress Website via CLI
# ==========================================

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

# === Load config & logic ===
CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi
source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/website_loader.sh"

# === Parse argument ===
for arg in "$@"; do
  case $arg in
    --site=*) SITE_NAME="${arg#*=}" ;;
  esac
done

if [[ -z "$SITE_NAME" ]]; then
  echo "❌ Missing required --site=SITE_NAME parameter"
  exit 1
fi

# === Run deletion logic ===
website_management_delete_logic "$SITE_NAME"
