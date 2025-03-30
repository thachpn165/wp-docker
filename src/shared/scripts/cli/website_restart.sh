#!/usr/bin/env bash

# ==========================================
# 🔄 website_restart.sh – Restart a WordPress Website via CLI
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
    --site_name=*) SITE_NAME="${arg#*=}" ;;
  esac
done

if [[ -z "$SITE_NAME" ]]; then
  echo "❌ Missing required --site_name=SITE_NAME parameter"
  exit 1
fi

# === Restart Website Logic ===
echo "🔄 Restarting WordPress website: $SITE_NAME"

# Stop and remove containers related to the site
docker-compose -f "$SITES_DIR/$SITE_NAME/docker-compose.yml" down || {
  echo "❌ Failed to stop containers for $SITE_NAME"
  exit 1
}

# Restart containers
docker-compose -f "$SITES_DIR/$SITE_NAME/docker-compose.yml" up -d || {
  echo "❌ Failed to restart containers for $SITE_NAME"
  exit 1
}

echo "✅ Website $SITE_NAME has been restarted successfully."
