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
  if ! is_test_mode; then
    "$@"
  else
    echo "🧪 Skipping in TEST_MODE: $*" >&2
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
    read -p "$prompt" input
    echo "${input:-$fallback}"
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
