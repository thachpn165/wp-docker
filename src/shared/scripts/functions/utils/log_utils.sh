debug_log() {
  [[ "$DEBUG_MODE" == "true" ]] && echo -e "🐛 [DEBUG] $1"
}

# Function to run command and suppress output
run_cmd() {
  local cmd="$*"
  if [[ "$DEBUG_MODE" == "true" ]]; then
    echo -e "🐛 [CMD] $cmd"
    eval "$cmd"
  else
    eval "$cmd" &>/dev/null
  fi
}

# Function to run command and capture output
run_cmd_output() {
  local cmd="$*"
  if [[ "$DEBUG_MODE" == "true" ]]; then
    echo -e "🐛 [CMD] $cmd"
  fi
  eval "$cmd"
}

# Function to write log with timestamp, avoid duplicate logs
log_with_time() {
    local message="$1"
    local formatted_time
    formatted_time="$(date '+%Y-%m-%d %H:%M:%S') - $message"

    # Print to terminal and write to log simultaneously
    echo -e "$formatted_time"  # Print to terminal
    echo -e "$formatted_time" >> "$log_file"  # Append to log file
}
