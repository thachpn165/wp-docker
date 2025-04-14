# =====================================
# debug_log: Display debug message if DEBUG_MODE is enabled
# Parameters: $1 - message to log
# =====================================
debug_log() {
  local message="$1"
  if [[ "$DEBUG_MODE" == "true" ]]; then
    local source_file="${BASH_SOURCE[1]}"
    local line_number="${BASH_LINENO[0]}"
    local func_name="${FUNCNAME[1]}"
    log_with_time "🐛 ${BLUE}[DEBUG]${NC} $source_file:$line_number [$func_name] → $message"
  fi
}

# =====================================
# log_with_time: Log a message with timestamp to stderr and log file
# Parameters: $1 - message to log
# =====================================
log_with_time() {
  local message="$1"
  local formatted_time
  formatted_time="$(date '+%Y-%m-%d %H:%M:%S') - $message"

  # Output to terminal as STDERR to avoid interfering with stdout
  echo -e "$formatted_time" >&2

  # Write to log file if set
  if [[ -n "$DEBUG_LOG" ]]; then
    echo -e "$formatted_time" >> "$DEBUG_LOG"
  fi
}

# =====================================
# print_and_debug: Print a message and log it if DEBUG_MODE is enabled
# Parameters:
#   $1 - message type (info, error, warning, etc.)
#   $2 - message content
# =====================================
print_and_debug() {
  local type="$1"       # info, error, warning,...
  local message="$2"

  print_msg "$type" "$message"

  if [[ "$DEBUG_MODE" == "true" ]]; then
    local source_file="${BASH_SOURCE[1]}"
    local line_number="${BASH_LINENO[0]}"
    local func_name="${FUNCNAME[1]}"
    log_with_time "🐛 ${BLUE}[$type]${NC} $source_file:$line_number [$func_name] → $message"
  fi
}

# =====================================
# run_cmd: Run a command or function with optional debug and error handling
# Parameters:
#   $1 - command or function call string
#   $2 - exit_on_fail (true/false, default: false)
# =====================================
run_cmd() {
    ensure_safe_cwd
    local cmd="$1"
    local exit_on_fail="${2:-false}"

    local source_file="${BASH_SOURCE[1]}"
    local line_number="${BASH_LINENO[0]}"
    local func_name="${FUNCNAME[1]}"

    if [[ "$cmd" == *"$0"* ]]; then
        print_and_debug error "❌ Detected self-invoking command → $cmd"
        return 1
    fi

    # Detect if it's a bash function
    local is_function=false
    if declare -f "${cmd%% *}" >/dev/null 2>&1; then
        is_function=true
    fi

    if [[ "$DEBUG_MODE" == "true" ]]; then
        log_with_time "🐛 ${BLUE}[CMD]${NC} $source_file:$line_number [$func_name] → $cmd"
    fi

    if [[ "$is_function" == "true" ]]; then
        # Call function directly with arguments
        eval "$cmd"
    else
        # Execute as bash command
        if [[ "$DEBUG_MODE" == "true" ]]; then
            bash -c "$cmd" 2>&1 | tee -a "$DEBUG_LOG"
        else
            eval "$cmd" &>/dev/null
        fi
    fi

    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        print_and_debug error "$ERROR_COMMAND_FAILED: $cmd"
        [[ "$exit_on_fail" == "true" ]] && exit 1
        return 1
    fi
    ensure_safe_cwd
    return 0
}