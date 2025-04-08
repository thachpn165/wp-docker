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

# === Parse Arguments ===
force_update=false

for arg in "$@"; do
  case "$arg" in
    --force)
      force_update=true
      ;;
  esac
done

# === Run Update Logic ===
if [[ "$force_update" == true ]]; then
  core_update_system --force
else
  core_update_system
fi