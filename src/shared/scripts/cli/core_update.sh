#!/bin/bash
# =====================================
# ⚙️ CLI Wrapper – core_update.sh
# =====================================

# ✅ Load configuration from any location
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
SEARCH_PATH="$SCRIPT_PATH"
while [[ "$SEARCH_PATH" != "/" ]]; do
  if [[ -f "$SEARCH_PATH/shared/config/load_config.sh" ]]; then
    source "$SEARCH_PATH/shared/config/load_config.sh"
    load_config_file
    break
  fi
  SEARCH_PATH="$(dirname "$SEARCH_PATH")"
done
source "$FUNCTIONS_DIR/core_loader.sh"

# === Run Update Logic ===
core_version_update_latest