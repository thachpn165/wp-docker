#!/bin/bash

# === 🧠 Auto-detect PROJECT_DIR (source code root) ===
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

# === ${CHECKMARK} Load config.sh from PROJECT_DIR ===
CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "${CROSSMARK} Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi
safe_source "$CONFIG_FILE"

# === ${CHECKMARK} Load update_core.sh to use update functions ===
UPDATE_CORE_FILE="$PROJECT_DIR/shared/scripts/functions/core/update_core.sh"
if [[ ! -f "$UPDATE_CORE_FILE" ]]; then
  echo "${CROSSMARK} Update core file not found at: $UPDATE_CORE_FILE" >&2
  exit 1
fi
safe_source "$UPDATE_CORE_FILE"

# === 🔄 Run complete update process ===
core_update_system  # Call update function from update_core.sh
