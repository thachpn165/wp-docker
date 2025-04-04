#!/bin/bash
# ======================================
# CLI wrapper: Run WP-CLI inside container for a given site
# ======================================

# === Load config & loader ===
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
  echo "${CROSSMARK} Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi
source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/wordpress_loader.sh"

# === Parse arguments ===
domain=""
params=()

for arg in "$@"; do
  case $arg in
    --domain=*) domain="${arg#*=}" ;;
    *) params+=("$arg") ;;
  esac
done

if [[ -z "$domain" ]]; then
  echo "${CROSSMARK} Missing required --domain=SITE_DOMAIN parameter"
  exit 1
fi

# === Call logic ===
wordpress_wp_cli_logic "$domain" "${params[@]}"