#!/bin/bash
# ✅ Safely locate BASE_DIR and load config.sh
# Can be called from ANY subpath

if [[ -n "$CONFIG_FILE_LOADED" ]]; then return 0; fi

# === Helper: Load config.sh
load_config_file() {
  if [[ -z "$PROJECT_DIR" ]]; then
    SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
    
    # Iterate upwards from the current script directory to find 'config.sh'
    while [[ "$SCRIPT_PATH" != "/" ]]; do
      if [[ -f "$SCRIPT_PATH/shared/config/config.sh" ]]; then
        PROJECT_DIR="$SCRIPT_PATH"
        break
      fi
      SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
    done

    # Handle error if config file is not found
    if [[ -z "$PROJECT_DIR" ]]; then
      echo "${CROSSMARK} Unable to determine PROJECT_DIR. Please check the script's directory structure." >&2
      exit 1
    fi
  fi

  # Load the config file if PROJECT_DIR is set
  CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "${CROSSMARK} Config file not found at: $CONFIG_FILE" >&2
    exit 1
  fi

  # Source the config file
  source "$CONFIG_FILE"
}


# === Auto-load config.sh
load_config_file