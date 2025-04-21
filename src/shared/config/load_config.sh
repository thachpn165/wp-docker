#!/bin/bash

# =====================================
# 🐞 debug_process – Enable detailed shell tracing
# =====================================
debug_process() {
    if [[ "$DEBUG_MODE" == "true" ]]; then
        export PS4='\e[36m+(${BASH_SOURCE}:${LINENO}):\e[0m ${FUNCNAME[0]:+\e[35m${FUNCNAME[0]}():\e[0m }'
        set -x
    else
        echo "Debug mode is not enabled. Set DEBUG_MODE=true to enable debugging."
    fi
}

# =====================================
# 🛡 safe_source – Source file safely with debug info & prevention of double-sourcing
# Parameters:
#   $1 - target file to source
# Behavior:
#   - Checks if file has already been sourced
#   - Outputs debug info if DEBUG_MODE=true
# =====================================
safe_source() {
  local target_file="$1"
  local caller_file="${BASH_SOURCE[1]}"
  local var_name
  var_name="WPDK_LOADED_$(realpath "$target_file" 2>/dev/null | tr './-' '_')"

  local green='\033[0;32m'
  local yellow='\033[0;33m'
  local red='\033[0;31m'
  local reset='\033[0m'

  # Check if already sourced
  if [[ "$(eval echo \${$var_name:-false})" == "true" ]]; then
    [[ "$DEBUG_MODE" == "true" ]] && echo -e "${green}[SAFE_SOURCE]${reset} File ${yellow}${target_file}${reset} already sourced, skipping."
    return 0
  fi

  # Mark as sourced
  eval "$var_name=true"

  [[ "$DEBUG_MODE" == "true" ]] && echo -e "${green}[SOURCE]${reset} From ${yellow}${caller_file:-unknown}${reset} → ${yellow}${target_file}${reset}"

  # File existence check
  if [[ ! -f "$target_file" ]]; then
    echo -e "${red}[SOURCE ERROR]${reset} File ${yellow}${target_file}${reset} not found!"
    return 1
  fi

  # Source and check status
  builtin source "$target_file"
  local status=$?

  if [[ "$DEBUG_MODE" == "true" ]]; then
    if [[ $status -eq 0 ]]; then
      echo -e "${green}[SOURCE]${reset} Successfully sourced ${yellow}${target_file}${reset}"
    else
      echo -e "${red}[SOURCE ERROR]${reset} Failed to source ${yellow}${target_file}${reset} (exit code $status)"
    fi
  fi

  return $status
}

# =====================================
# ⚙️ load_config_file – Auto-detect and load shared/config/config.sh
# Behavior:
#   - Recursively walks up from script path to locate config.sh
#   - Sets PROJECT_DIR and sources the config safely
# =====================================
load_config_file() {
  if [[ -z "$PROJECT_DIR" ]]; then
    SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"

    # Walk up to find shared/config/config.sh
    while [[ "$SCRIPT_PATH" != "/" ]]; do
      if [[ -f "$SCRIPT_PATH/shared/config/config.sh" ]]; then
        PROJECT_DIR="$SCRIPT_PATH"
        break
      fi
      SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
    done

    if [[ -z "$PROJECT_DIR" ]]; then
      echo "${CROSSMARK} Unable to determine PROJECT_DIR. Check directory structure." >&2
      exit 1
    fi
  fi

  CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "${CROSSMARK} Config file not found at: $CONFIG_FILE" >&2
    exit 1
  fi

  safe_source "$CONFIG_FILE"
}

# =====================================
# 🚀 Auto-load config at runtime
# =====================================
# Tự động tải config nếu chưa được gọi
if ! declare -F load_config_file &>/dev/null; then
    load_config_file
fi
