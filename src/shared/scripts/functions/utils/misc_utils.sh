# Define utility functions that don't belong to a specific category
ensure_safe_cwd() {
  if ! pwd &>/dev/null; then
    cd "$BASE_DIR" || cd /
    debug_log "[ensure_safe_cwd] ❗️Detected invalid CWD → Recovered to $BASE_DIR"
  fi
}

# ❌ Exit if the last command failed
# Usage:
#   exit_if_error $? "An error occurred"
# Arguments:
#   1. result (int): Exit code of the previous command
#   2. error_message (string): Error message to display if failed
# Behavior:
#   - Prints error in red and returns 1 if result is non-zero.
#   - Otherwise does nothing.
exit_if_error() { 
    local result=$1
    local error_message=$2
    if [[ $result -ne 0 ]]; then
        print_msg error "$error_message"
        return 1
    fi
}
# =========================================
# 🧪 TEST_MODE Support Functions
# =========================================

# 🧪 Check if running in test mode
# Returns:
#   - true if TEST_MODE is enabled
is_test_mode() {
  [[ "$TEST_MODE" == true ]]
}

# 🧪 Run command unless in TEST_MODE (returns fallback if test)
# Usage:
#   value=$(run_if_not_test "fallback" some_function)
# Arguments:
#   1. fallback: Value to return in test mode
#   2. command: Function or command to run if not in test mode
run_if_not_test() {
  local fallback="$1"
  shift
  if is_test_mode; then
    echo "$fallback"
  else
    "$@"
  fi
}

# 🧪 Execute command only if not in test mode
# Usage:
#   run_unless_test docker compose up -d
# Notes:
#   - Does nothing in TEST_MODE (for CI testing)
run_unless_test() {
  if [[ "$TEST_MODE" == true && "$BATS_TEST_FILENAME" != "" ]]; then
    #echo "[MOCK run_unless_test] $*"
    return 0
  else
    "$@"
  fi
}


# 🧪 Prompt user or use fallback in TEST_MODE
# Usage:
#   value=$(get_input_or_test_value "Enter value: " "test-default")
get_input_or_test_value() {
  local prompt="$1"
  local fallback="$2"

  if is_test_mode; then
    echo "$fallback"
  else
    [[ "$TEST_MODE" != true ]] && read -p "$prompt" input
    echo "${input:-$fallback}"
  fi
}

# 🧪 Prompt user for secret input or use fallback in TEST_MODE
get_input_or_test_value_secret() {
  local prompt="$1"
  local fallback="$2"
  local input=""

  if is_test_mode; then
    # Trong chế độ test, trả về fallback mà không cần prompt
    echo "$fallback"
  else
    # Hiển thị prompt mà không cần xuống dòng
    printf "%s" "$prompt"
    # Đọc mật khẩu mà không hiển thị ra màn hình
    read -s input
    # Hiển thị lại dòng mới sau khi nhập
    echo
    # Trả về giá trị nhập hoặc fallback nếu không có giá trị
    echo "${input:-$fallback}"
  fi
}

# 🔢 Prompt user to select from a list (or auto-select in test mode)
# Usage:
#   selected=$(select_from_list "Choose option:" "${options[@]}")
# Notes:
#   - In TEST_MODE, auto-selects first or TEST_SELECTED_OPTION
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


# =========================================
# Other Functions
# =========================================

# 🔄 Show a loading animation (spinner)
# Usage:
#   show_loading "Loading..." 0.1
# Arguments:
#   1. message: Text to display before spinner
#   2. delay: Delay in seconds between spinner frames
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
    echo -ne "\b \b"  # Clear loading symbol
    echo ""
  fi
}

# 📋 Fetch a variable value from a .env file
# Usage:
#   value=$(fetch_env_variable ".env" "DB_NAME")
# Returns:
#   - The value of the specified variable, or exits with error if file not found
fetch_env_variable() {
    local env_file="$1"
    local var_name="$2"

    if [ -f "$env_file" ]; then
        grep -E "^${var_name}=" "$env_file" \
          | cut -d'=' -f2- \
          | tr -d '\r' \
          | sed 's/^"\(.*\)"$/\1/'
    else
        echo -e "${RED}${CROSSMARK} Error: .env file does not exist: $env_file${NC}" >&2
        debug_log "[fetch_env_variable] Error: .env file does not exist: $env_file"
        return 1
    fi
}

# ===========================================================
# 🖨️ print_msg <type> <message>
# -----------------------------------------------------------
# Display formatted message with color + emoji based on type.
# Automatically prints to terminal in a consistent, readable format.
#
# Usage:
#   print_msg success "Installation completed!"
#   print_msg error "Database connection failed."
#   print_msg warning "Low disk space warning."
#   print_msg info "Starting update..."
#   print_msg progress "Uploading files..."
#
# Supported types:
#   - success     ✅ Green      (successfully completed)
#   - error       ❌ Red        (critical error)
#   - warning     ⚠️  Yellow     (non-blocking warning)
#   - info        ℹ️  White      (informational)
#   - save        💾 White      (for saving configurations)
#   - important   🚨 Red        (important alert)
#   - debug       🐛 Cyan       (debug logs, visible in DEBUG_MODE)
#   - step        ➤  Magenta    (step by step)
#   - check       🔍 Cyan       (checking something)
#   - run         🚀 Green      (currently executing something)
#   - skip        ⏭️  Yellow     (skipping a step)
#   - cancel      🛑 Red        (user cancelled or aborted)
#   - question    ❓ White      (prompt input from user)
#   - completed   🏁 Green      (final completion of task/process)
#   - progress    🚀 + spinner  (displays loading animation via show_loading)
#
# Recommended with i18n:
#   print_msg error "$MSG_SITE_NOT_FOUND"
#   print_msg success "$MSG_BACKUP_SUCCESS"
# ===========================================================
print_msg() {
  local type="$1"
  local message="$2"
  local color emoji

  case "$type" in
    success)     emoji="✅" color="$GREEN" ;;
    error)       emoji="❌" color="$RED" ;;
    warning)     emoji="⚠️"  color="$YELLOW" ;;
    info)        emoji=""  color="$WHITE" ;;
    save)        emoji="💾" color="$WHITE" ;;
    important)   emoji="🚨" color="$RED" ;;
    step)        emoji="➤"  color="$MAGENTA" ;;
    check)       emoji="🔍" color="$CYAN" ;;
    run)         emoji="🚀" color="$GREEN" ;;
    skip)        emoji="⏭️"  color="$YELLOW" ;;
    cancel)      emoji="🛑" color="$RED" ;;
    question)    emoji="❓" color="$WHITE" ;;
    completed)   emoji="🏁" color="$GREEN" ;;
    recommend)   emoji="💡" color="$BLUE" ;;
    title)     emoji="" color="$CYAN" ;;
    label)     emoji="" color="$BLUE" ;;
    sub_label) emoji="" color="$WHITE" ;;
    copy)      emoji="→" color="$GREEN";;
    tip)     emoji="💡" color="$YELLOW";;
    
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

get_user_confirmation() {
  local message="$1"
  local confirm

  while true; do
    get_input_or_test_value "$message (y/n): " "y"
    confirm="$REPLY"
    case "$confirm" in
      [Yy]*) return 0 ;;
      [Nn]*) return 1 ;;
      *) print_msg warning "$WARNING_INVALID_YN";;
    esac
  done
}

