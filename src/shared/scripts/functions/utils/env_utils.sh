#!/bin/bash

# ============================================
# 🌱 Environment Variable Utilities
# ============================================

# Declare functions if not already declared
if ! declare -f log_with_time > /dev/null; then
  log_with_time() {
      local message="$1"
      local formatted_time
      formatted_time="$(date '+%Y-%m-%d %H:%M:%S') - $message"

      # Output to terminal
      echo -e "$formatted_time"
      # Write to file if DEBUG_LOG variable is set
      if [[ -n "$DEBUG_LOG" ]]; then
          echo -e "$formatted_time" >> "$DEBUG_LOG"
      fi
  }
fi

if ! declare -f print_and_debug > /dev/null; then
  print_and_debug() {
      local type="$1"       # info, error, warning,...
      local message="$2"

      print_msg "$type" "$message"

      if [[ "$DEBUG_MODE" == "true" ]]; then
          local source_file="${BASH_SOURCE[1]}"
          local line_number="${BASH_LINENO[0]}"
          local func_name="${FUNCNAME[1]}"
          log_with_time "🐛 [$type] $source_file:$line_number [$func_name] → $message"
      fi
  }
fi

if ! declare -f debug_log > /dev/null; then
    debug_log() {
        local message="$1"
        if [[ "$DEBUG_MODE" == "true" ]]; then
            # Lấy thông tin file và dòng gọi hàm debug_log
            local source_file="${BASH_SOURCE[1]}"
            local line_number="${BASH_LINENO[0]}"
            local func_name="${FUNCNAME[1]}"

            log_with_time "🐛 [DEBUG] $source_file:$line_number [$func_name] → $message"
        fi
    }
fi


# Load config if not already loaded
if [[ -z "$PROJECT_DIR" ]]; then
  print_and_debug error "$ERROR_PROJECT_DIR_NOT_SET"
  return 1
fi

# === Get value from .env ===
env_get_value() {
  local env_file="$1"
  local key="$2"

  if [[ ! -f "$env_file" ]]; then
    print_and_debug error "$(printf "$ERROR_ENV_FILE_NOT_FOUND" "$env_file")"
    return 1
  fi

  grep -E "^${key}=" "$env_file" | cut -d '=' -f2- | tr -d '"'
}

# === Set or update a key=value in .env ===
env_set_value() {
  local key="$1"
  local value="$2"
  local env_file="$CORE_ENV"

  if [[ ! -f "$env_file" ]]; then
    touch "$env_file" || {
      print_and_debug error "$(printf "$ERROR_CREATE_ENV_FILE_FAILED" "$env_file")"
      return 1
    }
  fi

  if grep -qE "^${key}=" "$env_file"; then
    sedi "s|^${key}=.*|${key}=\"${value}\"|" "$env_file"
  else
    echo "${key}=\"${value}\"" >> "$env_file"
  fi
}

# === Load environment variables from .env file ===
env_load() {
  local env_file="${CORE_ENV:-$BASE_DIR/.env}"

  if [[ -f "$env_file" ]]; then
    debug_log "Loading .env file: $env_file"
    while IFS='=' read -r key value; do
      [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
      key=$(echo "$key" | xargs)
      temp_val="$value"
      temp_val=$(echo "$temp_val" | sed 's/^"//' | sed 's/"$//')
      export "$key=$temp_val"
    done < <(grep -v '^#' "$env_file")
  else
    print_msg warning "$(printf "$WARNING_ENV_FILE_NOT_FOUND" "$env_file")"
  fi
}
