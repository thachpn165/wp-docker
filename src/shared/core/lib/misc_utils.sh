# =============================================
# File: misc_utils.sh
# Description: This script contains utility functions for various purposes, including:
#   - Ensuring safe current working directory
#   - Handling errors and exit codes
#   - Supporting test mode operations
#   - User input handling
#   - Spinner animations
#   - Fetching environment variables
#   - Printing formatted messages
#   - Secure curl wrapper
#   - Parsing and formatting sizes
#
# Functions:
#   - ensure_safe_cwd: Ensure current working directory is valid
#       Parameters: None
#   - exit_if_error: Exit or return error if last command failed
#       Parameters: $1 - exit code, $2 - error message
#   - run_if_not_test: Run command unless in TEST_MODE
#       Parameters: $1 - fallback, $2+ - command
#   - run_unless_test: Execute command only if not in TEST_MODE
#       Parameters: $@ - command
#   - get_input_or_test_value: Prompt user for input or fallback in TEST_MODE
#       Parameters: $1 - prompt message, $2 - fallback value
#   - select_from_list: Prompt to select from list or auto-select in TEST_MODE
#       Parameters: $1 - prompt message, $2... - list options
#   - start_loading: Show spinner loading animation
#       Parameters: $1 - message, $2 - delay (optional, default 0.1s)
#   - stop_loading: Stop spinner animation
#       Parameters: None
#   - print_msg: Display formatted message with color and emoji
#       Parameters: $1 - type, $2 - message
#   - safe_curl: Secure and validated curl wrapper
#       Parameters: $1 - URL to fetch
#   - parse_size_to_bytes: Convert human-readable size to bytes
#       Parameters: $1 - size string (e.g., "10KB", "1.5MB", "2GB")
#   - format_bytes: Format bytes into human-readable units
#       Parameters: $1 - number of bytes
# =============================================

ensure_safe_cwd() {
  if ! pwd &>/dev/null; then
    cd "$BASE_DIR" || cd /
    debug_log "[ensure_safe_cwd] ❗️Detected invalid CWD → Recovered to $BASE_DIR"
  fi
}

exit_if_error() {
  local result=$1
  local error_message=$2
  if [[ $result -ne 0 ]]; then
    print_msg error "$error_message"
    return 1
  fi
}

run_if_not_test() {
  local fallback="$1"
  shift
  if _is_test_mode; then
    echo "$fallback"
  else
    "$@"
  fi
}

run_unless_test() {
  if [[ "$TEST_MODE" == true && "$BATS_TEST_FILENAME" != "" ]]; then
    return 0
  else
    "$@"
  fi
}

get_input_or_test_value() {
  local prompt="$1"
  local fallback="$2"
  local input=""

  if _is_test_mode; then
    echo "$fallback"
  else
    read -p "$prompt" input
    echo "${input:-$fallback}"
  fi
}

select_from_list() {
  local prompt="$1"
  shift
  local options=("$@")

  if [[ "$TEST_MODE" == true ]]; then
    local test_value="${TEST_SELECTED_OPTION:-${options[0]}}"
    echo "$test_value"
    return 0
  fi

  local choice
  [[ "$TEST_MODE" != true ]] && read -p "$prompt [1-${#options[@]}]: " choice
  if [[ "$choice" =~ ^[0-9]+$ && "$choice" -ge 1 && "$choice" -le ${#options[@]} ]]; then
    echo "${options[$((choice - 1))]}"
    return 0
  else
    echo ""
    return 1
  fi
}

start_loading() {
  local message="$1"
  local delay="${2:-0.1}"
  local symbols=("/" "-" "\\" "|")

  print_msg info "$message "

  if [[ "$DEBUG_MODE" == true ]]; then
    return
  fi
  (
    while true; do
      for symbol in "${symbols[@]}"; do
        echo -n "$symbol"
        sleep "$delay"
        echo -ne "\b"
      done
    done
  ) &
  LOADING_PID=$!
}

stop_loading() {
  if [[ -n "$LOADING_PID" ]]; then
    kill "$LOADING_PID" &>/dev/null
    wait "$LOADING_PID" 2>/dev/null
    unset LOADING_PID
    echo -ne "\b \b"
    echo ""
  fi
}

print_msg() {
  local type="$1"
  local message="$2"
  local color emoji

  case "$type" in
  success) emoji="✅" color="$GREEN" ;;
  error) emoji="❌" color="$RED" ;;
  warning) emoji="⚠️" color="$YELLOW" ;;
  info) emoji="ℹ️" color="$WHITE" ;;
  save) emoji="💾" color="$WHITE" ;;
  important) emoji="🚨" color="$RED" ;;
  step) emoji="➤" color="$MAGENTA" ;;
  check) emoji="🔍" color="$CYAN" ;;
  run) emoji="🚀" color="$GREEN" ;;
  skip) emoji="⏭️" color="$YELLOW" ;;
  cancel) emoji="🛑" color="$RED" ;;
  question) emoji="❓" color="$WHITE" ;;
  completed) emoji="🏁" color="$GREEN" ;;
  recommend) emoji="💡" color="$BLUE" ;;
  title) emoji="📌" color="$CYAN" ;;
  label) emoji="" color="$BLUE" ;;
  sub_label) emoji="➥" color="$WHITE" ;;

  progress)
    emoji="🚀"
    color="$GREEN"
    start_loading "${color}${emoji} ${message}${NC}" 2
    return
    ;;
  *)
    echo -e "$message"
    return
    ;;
  esac

  echo -e "${color}${emoji} ${message}${NC}"
}

safe_curl() {
  local url="$1"

  if [[ -z "$url" ]]; then
    print_msg error "❌ Missing URL in safe_curl"
    return 1
  fi

  local validated_url
  validated_url=$(network_check_http "$url") || return 1

  curl --fail --silent --show-error --location --max-time 30 "$validated_url"
}

parse_size_to_bytes() {
  local size_str="$1"
  local num unit
  num=$(echo "$size_str" | grep -Eo '^[0-9.]+')
  unit=$(echo "$size_str" | grep -Eo '[A-Z]+$')

  case "$unit" in
    B) echo "$num" | awk '{printf "%d", $1}' ;;
    KB) echo "$num" | awk '{printf "%d", $1 * 1024}' ;;
    MB) echo "$num" | awk '{printf "%d", $1 * 1024 * 1024}' ;;
    GB) echo "$num" | awk '{printf "%d", $1 * 1024 * 1024 * 1024}' ;;
    TB) echo "$num" | awk '{printf "%d", $1 * 1024 * 1024 * 1024 * 1024}' ;;
    *) echo 0 ;;
  esac
}

format_bytes() {
  num=$1
  if (( num >= 1099511627776 )); then
    awk -v n=$num 'BEGIN { printf "%.2f TB", n / 1099511627776 }'
  elif (( num >= 1073741824 )); then
    awk -v n=$num 'BEGIN { printf "%.2f GB", n / 1073741824 }'
  elif (( num >= 1048576 )); then
    awk -v n=$num 'BEGIN { printf "%.2f MB", n / 1048576 }'
  elif (( num >= 1024 )); then
    awk -v n=$num 'BEGIN { printf "%.2f KB", n / 1024 }'
  else
    echo "$num B"
  fi
}
