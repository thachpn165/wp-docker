#!/bin/bash
# 🔧 Auto-detect BASE_DIR and load global configuration
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
  if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
    source "$SCRIPT_PATH/shared/config/load_config.sh"
    break
  fi
  SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done
source "$FUNCTIONS_DIR/core_loader.sh"
# === Parse --channel from argument ===
for arg in "$@"; do
  case $arg in
    --channel=*) CHANNEL="${arg#*=}" ;;
    *)
      print_and_debug error "$ERROR_UNKNOW_PARAM: $arg"
      print_and_debug info "$INFO_PARAM_EXAMPLE:\n  --channel=official/nightly"
      exit 1
      ;;
  esac
done

core_set_channel "$CHANNEL"