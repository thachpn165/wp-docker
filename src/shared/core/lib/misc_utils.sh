# =====================================
# ensure_safe_cwd: Ensure current working directory is valid
# Behavior: If invalid, recover to $BASE_DIR or root
# =====================================
ensure_safe_cwd() {
  if ! pwd &>/dev/null; then
    cd "$BASE_DIR" || cd /
    debug_log "[ensure_safe_cwd] ❗️Detected invalid CWD → Recovered to $BASE_DIR"
  fi
}

# =====================================
# exit_if_error: Exit or return error if last command failed
# Parameters:
#   $1 - exit code
#   $2 - error message
# =====================================
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

# =====================================
# run_if_not_test: Run command unless in TEST_MODE
# Parameters:
#   $1 - fallback
#   $2+ - command
# Returns: result of command or fallback
# =====================================
run_if_not_test() {
  local fallback="$1"
  shift
  if _is_test_mode; then
    echo "$fallback"
  else
    "$@"
  fi
}

# =====================================
# run_unless_test: Execute command only if not in TEST_MODE
# Skips execution in CI testing mode
# =====================================
run_unless_test() {
  if [[ "$TEST_MODE" == true && "$BATS_TEST_FILENAME" != "" ]]; then
    #echo "[MOCK run_unless_test] $*"
    return 0
  else
    "$@"
  fi
}

# =====================================
# get_input_or_test_value: Prompt user for input or fallback in TEST_MODE
# Parameters:
#   $1 - prompt message
#   $2 - fallback value
# Returns: user input or fallback
# =====================================
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

# =====================================
# select_from_list: Prompt to select from list or auto-select in TEST_MODE
# Parameters:
#   $1 - prompt message
#   $2... - list options
# Returns: selected option
# =====================================
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

# =====================================
# start_loading: Show spinner loading animation
# Parameters:
#   $1 - message
#   $2 - delay (optional, default 0.1s)
# =====================================
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

# =====================================
# stop_loading: Stop spinner animation
# =====================================
stop_loading() {
  if [[ -n "$LOADING_PID" ]]; then
    kill "$LOADING_PID" &>/dev/null
    wait "$LOADING_PID" 2>/dev/null
    unset LOADING_PID
    echo -ne "\b \b" # Clear loading symbol
    echo ""
  fi
}

# 📋 Fetch a variable value from a .env file
# Usage:
#   value=$(fetch_env_variable ".env" "DB_NAME")
# Returns:
#   - The value of the specified variable, or exits with error if file not found

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

# =============================================
# 🌐 safe_curl – Secure and validated curl wrapper (pipeable version)
# ---------------------------------------------
# Usage:
#   safe_curl "<url>" | bash
# Parameters:
#   $1 - URL to fetch
# Behavior:
#   - Validates and upgrades URL via network_check_http
#   - Executes curl with best practices and outputs to stdout
# =============================================
safe_curl() {
  local url="$1"

  if [[ -z "$url" ]]; then
    print_msg error "❌ Missing URL in safe_curl"
    return 1
  fi

  # 🧠 Lấy URL đã chuyển hướng (HTTPS)
  local validated_url
  validated_url=$(network_check_http "$url") || return 1

  # ✅ Dùng URL đã chuẩn hóa
  curl --fail --silent --show-error --location --max-time 30 "$validated_url"
}
