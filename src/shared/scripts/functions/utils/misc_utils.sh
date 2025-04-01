# Define utility functions that don't belong to a specific category

# =========================================
# 🧪 System Environment Related
# =========================================
# 📝 **Check Required Environment Variables**
check_required_envs() {
  for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
      echo -e "${RED}❌ Error: Variable '$var' is not defined in config.sh${NC}"
      exit 1
    fi
  done
}


# Exit if the last command failed
# Usage:
#   exit_if_error $? "An error occurred while executing the command."
# Arguments:
#   1. result (int): The exit status of the last command.
#   2. error_message (string): The error message to display if the command failed.
# Behavior:
#   - If the result is not 0, it prints the error message in red and returns 1.
#   - If the result is 0, it does nothing and returns 0.
#   - This function is useful for error handling in scripts, allowing you to check the success
#     or failure of a command and take appropriate action.
exit_if_error() { 
    local result=$1
    local error_message=$2
    if [[ $result -ne 0 ]]; then
        echo -e "${RED}${error_message}${NC}"
        return 1
    fi
}
# =========================================
# 🧪 TEST_MODE Support Functions
# =========================================

# ✅ Check if running in test mode
is_test_mode() {
  [[ "$TEST_MODE" == true ]]
}

# ✅ Execute command if not in test mode, return fallback value if in test mode
# Usage:
#   domain=$(run_if_not_test "example.com" get_input_domain)
run_if_not_test() {
  local fallback="$1"
  shift
  if is_test_mode; then
    echo "$fallback"
  else
    "$@"
  fi
}

# ✅ Run a command (or function) only when not in TEST_MODE
# Usage:
#   run_unless_test docker compose up -d
run_unless_test() {
  if [[ "$TEST_MODE" == true && "$BATS_TEST_FILENAME" != "" ]]; then
    #echo "[MOCK run_unless_test] $*"
    return 0
  else
    "$@"
  fi
}


# ✅ Get input from user, or use test value if in TEST_MODE
# Usage:
#   domain=$(get_input_or_test_value "Enter domain: " "example.com")

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

# Select an item from a list, supports entering a number or choosing a default (used for website, storage, etc.)
# Function: select_from_list
# Arguments:
#   1. prompt (string): The message to display when prompting the user to select an option.
#   2. options (array): A list of options for the user to choose from.
# Behavior:
#   - If TEST_MODE is enabled, the function will automatically select the first item in the list
#     or the value of TEST_SELECTED_OPTION if it is set.
#   - If TEST_MODE is not enabled, the function will prompt the user to select an option by entering
#     a number corresponding to the desired item in the list.
#   - If the user enters a valid number within the range of the list, the function will return the
#     selected option.
#   - If the input is invalid, the function will return an empty string and exit with a status of 1.
# Select an item from a list, hỗ trợ nhập số hoặc chọn mặc định (dùng cho website, storage,...)
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

# Function to display loading animation
show_loading() {
    local message="$1"
    local delay="$2"  # Delay between rotation cycles (in seconds)
    
    # Create array of loading symbols
    local symbols=("/" "-" "\\" "|")
    
    # Loading animation loop
    echo -n "$message "
    while true; do
        for symbol in "${symbols[@]}"; do
            echo -n "$symbol"
            sleep "$delay"
            echo -ne "\b"  # Move cursor back one position (backspace)
        done
    done
}
