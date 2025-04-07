# =========================================
# 🐛 LOG UTILS - Support DEBUG_MODE + Logging
# =========================================

# Function to display logs when DEBUG_MODE=true
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

# Function to log with a timestamp (output to terminal + file)
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

# Function to print messages with a specific type (info, error, etc.)
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

# Function to execute a command, display when DEBUG_MODE=true, and handle errors smartly
# Usage:
#   run_cmd "<command>" [exit_on_fail]
# Example:
#   run_cmd "docker compose up -d" true    # Exit script if failed
#   run_cmd "rm somefile.txt"              # Just return 1 if failed

run_cmd() {
    local cmd="$1"
    local exit_on_fail="${2:-false}"  # Optional: set to "true" to exit on failure

    # Log the command if in DEBUG mode
    if [[ "$DEBUG_MODE" == "true" ]]; then
        local source_file="${BASH_SOURCE[1]}"
        local line_number="${BASH_LINENO[0]}"
        local func_name="${FUNCNAME[1]}"
        log_with_time "🐛 [CMD] $source_file:$line_number [$func_name] → $cmd"
        eval "$cmd" 2>&1 | tee -a "$DEBUG_LOG"
    else
        eval "$cmd" &>/dev/null
    fi

    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        print_and_debug error "$ERROR_COMMAND_FAILED: $cmd"
        if [[ "$exit_on_fail" == "true" ]]; then
            exit 1
        fi
        return 1
    fi

    return 0
}