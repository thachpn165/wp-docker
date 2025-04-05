#!/bin/bash
# === Load config & wordpress_loader.sh ===
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
source "$FUNCTIONS_DIR/wordpress_loader.sh"

# === Parse arguments ===
domain=""
for arg in "$@"; do
  case $arg in
    --domain=*) domain="${arg#*=}" ;;
    *) echo "❌ Unknown argument: $arg" && exit 1 ;;
  esac
done

if [[ -z "$domain" ]]; then
  echo "❌ Missing required parameter: --domain"
  exit 1
fi

# === Execute migration logic ===
wordpress_migration_logic "$domain"