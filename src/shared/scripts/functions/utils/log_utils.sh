# =========================================
# 🐛 LOG UTILS - Support DEBUG_MODE + Logging
# =========================================

# Function to display logs when DEBUG_MODE=true
debug_log() {
    local message="$1"
    if [[ "$DEBUG_MODE" == "true" ]]; then
        log_with_time "🐛 [DEBUG] $message"
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

# Function to execute a command, display it when DEBUG, and log output
run_cmd() {
    local cmd="$*"

    if [[ "$DEBUG_MODE" == "true" ]]; then
        log_with_time "🐛 [CMD] $cmd"
        eval "$cmd" 2>&1 | tee -a "$DEBUG_LOG"
    else
        eval "$cmd" &>/dev/null
    fi
}