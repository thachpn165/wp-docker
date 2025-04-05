#!/bin/bash
# ✅ Safely locate BASE_DIR and load config.sh
# Can be called from ANY subpath

if [[ -n "$CONFIG_FILE_LOADED" ]]; then return 0; fi

# === Auto-detect BASE_DIR (root of the repo)
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
SEARCH_DIR="$(dirname "$SCRIPT_PATH")"

while [[ "$SEARCH_DIR" != "/" ]]; do
  if [[ -f "$SEARCH_DIR/shared/config/config.sh" ]]; then
    BASE_DIR="$SEARCH_DIR"
    break
  fi
  SEARCH_DIR="$(dirname "$SEARCH_DIR")"
done

if [[ -z "$BASE_DIR" ]]; then
  echo "❌ Could not detect BASE_DIR (config.sh not found)" >&2
  exit 1
fi

# === Load config.sh once
CONFIG_FILE="$BASE_DIR/shared/config/config.sh"
source "$CONFIG_FILE"
export CONFIG_FILE_LOADED=true