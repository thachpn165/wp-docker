# ==================================================
# 🧠 System & CLI Utilities – Refactored for i18n
# ==================================================

# ============================================
# 🧠 get_total_ram – Retrieve total RAM in MB
# ============================================
# Description:
#   - Detects and returns the total RAM available in the system.
#   - Uses `free -m` on Linux, `sysctl` on macOS.
#
# Returns:
#   - Total RAM (in MB) as integer
get_total_ram() {
  if command -v free >/dev/null 2>&1; then
    free -m | awk '/^Mem:/{print $2}'
  else
    sysctl -n hw.memsize | awk '{print $1 / 1024 / 1024}'
  fi
}

# ============================================
# 🧠 get_total_cpu – Retrieve number of CPU cores
# ============================================
# Description:
#   - Detects and returns total number of CPU cores.
#   - Uses `nproc` on Linux, `sysctl` on macOS.
#
# Returns:
#   - Total number of CPU cores
get_total_cpu() {
  if command -v nproc >/dev/null 2>&1; then
    nproc
  else
    sysctl -n hw.ncpu
  fi
}

# ============================================
# 🛠 sedi – Cross-platform sed wrapper
# ============================================
# Description:
#   - Runs `sed -i` with proper syntax based on OS (macOS/Linux).
#
# Parameters:
#   - All parameters passed directly to sed command
#
# Globals:
#   OSTYPE
sedi() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# ============================================
# 🌐 setup_timezone – Ensure system timezone is Vietnam
# ============================================
# Description:
#   - On Linux, checks and sets system timezone to Asia/Ho_Chi_Minh if not already.
#
# Globals:
#   OSTYPE
#   WARNING_TIMEZONE_NOT_VIETNAM
#   SUCCESS_TIMEZONE_SET
setup_timezone() {
  if [[ "$OSTYPE" != "darwin"* ]]; then
    current_tz=$(timedatectl | grep "Time zone" | awk '{print $3}')
    if [[ "$current_tz" != "Asia/Ho_Chi_Minh" ]]; then
      print_msg warning "$WARNING_TIMEZONE_NOT_VIETNAM"
      timedatectl set-timezone Asia/Ho_Chi_Minh
      print_msg success "$SUCCESS_TIMEZONE_SET"
    fi
  fi
}

# ============================================
# 📝 choose_editor – Prompt user to select a CLI text editor
# ============================================
# Description:
#   - Lists available editors (`nano`, `vi`, `vim`, `micro`, `code`)
#   - Prompts user to select one
#   - Stores selection in global `EDITOR_CMD`
#
# Globals:
#   PROMPT_SELECT_EDITOR
#   PROMPT_CONFIRM_EDITOR
#   INFO_CHECKING_EDITORS
#   INFO_AVAILABLE_EDITORS
#   INFO_EDITOR_USAGE_GUIDE
#   WARNING_EDITOR_INVALID_SELECT
#   WARNING_EDITOR_CANCELLED
#   DEBUG_MODE
#
# Returns:
#   - 0 if an editor was selected
#   - 1 if canceled or invalid input
choose_editor() {
  print_msg info "$INFO_CHECKING_EDITORS"

  AVAILABLE_EDITORS=()
  [[ -x "$(command -v nano)" ]] && AVAILABLE_EDITORS+=("nano")
  [[ -x "$(command -v vi)" ]] && AVAILABLE_EDITORS+=("vi")
  [[ -x "$(command -v vim)" ]] && AVAILABLE_EDITORS+=("vim")
  [[ -x "$(command -v micro)" ]] && AVAILABLE_EDITORS+=("micro")
  [[ -x "$(command -v code)" ]] && AVAILABLE_EDITORS+=("code")

  if [[ ${#AVAILABLE_EDITORS[@]} -eq 0 ]]; then
    print_and_debug error "$ERROR_NO_EDITOR_FOUND"
    return 1
  fi

  print_msg info "$INFO_AVAILABLE_EDITORS"
  for i in "${!AVAILABLE_EDITORS[@]}"; do
    echo -e "  $((i + 1))) ${AVAILABLE_EDITORS[$i]}"
  done

  editor_index=$(get_input_or_test_value "$PROMPT_SELECT_EDITOR" "${TEST_EDITOR:-1}")

  if ! [[ "$editor_index" =~ ^[0-9]+$ ]] || ((editor_index < 1 || editor_index > ${#AVAILABLE_EDITORS[@]})); then
    print_msg warning "$WARNING_EDITOR_INVALID_SELECT"
    EDITOR_CMD="nano"
  else
    EDITOR_CMD="${AVAILABLE_EDITORS[$((editor_index - 1))]}"
  fi

  print_msg info "$(printf "$INFO_EDITOR_USAGE_GUIDE " "$EDITOR_CMD")"

  confirm=$(get_input_or_test_value "$PROMPT_CONFIRM_EDITOR " "${TEST_CONFIRM_EDITOR:-y}")
  if [[ "$confirm" =~ ^[Nn]$ ]]; then
    print_msg warning "$WARNING_EDITOR_CANCELLED"
    return 1
  fi

  return 0
}

# =====================================
# core_system_update_os_packages: Update system packages based on OS type
# No parameters
# Behavior:
#   - Detects OS type and runs appropriate update commands
#   - Uses --nogpgcheck for CentOS/AlmaLinux 8
# =====================================
core_system_update_os_packages() {
  echo "🔄 Updating system packages..."

  # Detect OS
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS_NAME="${NAME}"
    OS_VERSION_ID="${VERSION_ID}"
  elif [[ -f /etc/redhat-release ]]; then
    if grep -q "CentOS" /etc/redhat-release; then
      OS_NAME="CentOS"
      OS_VERSION_ID=$(grep -oE '[0-9]+\.[0-9]+' /etc/redhat-release | cut -d. -f1)
    elif grep -q "AlmaLinux" /etc/redhat-release; then
      OS_NAME="AlmaLinux"
      OS_VERSION_ID=$(grep -oE '[0-9]+\.[0-9]+' /etc/redhat-release | cut -d. -f1)
    fi
  fi

  echo "📌 Detected: ${OS_NAME} ${OS_VERSION_ID}"

  # Update based on OS type
  if [[ "$OS_NAME" == "CentOS" && "$OS_VERSION_ID" == "8" ]] ||
    [[ "$OS_NAME" == "AlmaLinux" && "$OS_VERSION_ID" == "8" ]]; then
    echo "🔄 Running CentOS/AlmaLinux 8 update with --nogpgcheck..."
    dnf update --nogpgcheck -y
  elif [[ "$OS_NAME" == "Ubuntu" ]]; then
    echo "🔄 Running Ubuntu update..."
    apt update -y && apt upgrade -y
  elif command -v apt &>/dev/null; then
    echo "🔄 Running apt-based update..."
    apt update -y && apt upgrade -y
  elif command -v dnf &>/dev/null; then
    echo "🔄 Running dnf-based update..."
    dnf update -y
  elif command -v yum &>/dev/null; then
    echo "🔄 Running yum-based update..."
    yum update -y
  else
    echo "⚠️ Unsupported operating system: ${OS_NAME}"
    return 1
  fi

  echo "✅ System update completed."
  return 0
}

# ============================================
# 🧪 core_system_check_required_commands – Ensure required commands are installed
# ============================================
# Description:
#   - Verifies availability of CLI tools like docker, jq, curl, unzip, etc.
#   - Installs missing ones depending on OS.
core_system_check_required_commands() {
  print_msg info "$INFO_CHECKING_COMMANDS"

  local cmd
  for cmd in $(echo "$CORE_REQUIRED_COMMANDS" | jq -r 'keys[]'); do
    if ! command -v "$cmd" &>/dev/null; then
      print_msg warning "$(printf "$WARNING_COMMAND_NOT_FOUND" "$cmd")"

      if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        local is_alma_centos8=false
        if [[ -f /etc/redhat-release ]]; then
          if (grep -q "AlmaLinux" /etc/redhat-release || grep -q "CentOS" /etc/redhat-release) && grep -q "8\." /etc/redhat-release; then
            is_alma_centos8=true
          fi
        fi

        if command -v apt &>/dev/null; then
          apt update -y && apt install -y "$cmd"
        elif command -v dnf &>/dev/null; then
          if [[ "$is_alma_centos8" == "true" ]]; then
            dnf install -y --nogpgcheck "$cmd"
          else
            dnf install -y "$cmd"
          fi
        elif command -v yum &>/dev/null; then
          if [[ "$is_alma_centos8" == "true" ]]; then
            yum install -y --nogpgcheck "$cmd"
          else
            yum install -y "$cmd"
          fi
        else
          print_msg error "$(printf "$ERROR_INSTALL_COMMAND_NOT_SUPPORTED" "$cmd")"
        fi
      elif [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v brew &>/dev/null; then
          print_msg warning "$WARNING_HOMEBREW_MISSING"
          /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install "$cmd"
      else
        print_msg error "$(printf "$ERROR_OS_NOT_SUPPORTED" "$cmd")"
      fi
    else
      print_msg success "$SUCCESS_COMMAND_AVAILABLE: $cmd"
    fi
  done
}

# =============================================
# 🌐 core_system_uninstall_required_commands
# ---------------------------------------------
# Uninstalls system commands based on the JSON
# variable CORE_REQUIRED_COMMANDS. Only commands
# marked with `"uninstall": true` will be removed.
#
# The function supports package managers:
# - apt (Debian/Ubuntu)
# - yum/dnf (RHEL/Alma/CentOS)
# - brew (macOS)
#
# For each command:
# - If it is marked `"uninstall": true` in the JSON,
#   and currently installed on the system, the function
#   attempts to uninstall it.
# - If the command is not installed, it is skipped.
#
# Useful for cleaning up optional CLI tools that are
# no longer needed in the runtime environment.
#
# Dependencies:
# - jq
# - Valid JSON structure in $CORE_REQUIRED_COMMANDS
# =============================================

core_system_uninstall_required_commands() {
  print_msg info "$INFO_UNINSTALLING_COMMANDS"

  local cmd uninstall_flag

  for cmd in $(echo "$CORE_REQUIRED_COMMANDS" | jq -r 'keys[]'); do
    uninstall_flag=$(echo "$CORE_REQUIRED_COMMANDS" | jq -r --arg cmd "$cmd" '.[$cmd].uninstall')

    if [[ "$uninstall_flag" != "true" ]]; then
      debug_log "[UNINSTALL] Skip $cmd (uninstall=false)"
      continue
    fi

    if ! command -v "$cmd" &>/dev/null; then
      print_msg skip "⏩ Command not installed: $cmd"
      continue
    fi

    print_msg warning "⚠️ Attempting to uninstall: $cmd"

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
      if command -v apt &>/dev/null; then
        apt remove -y "$cmd"
      elif command -v dnf &>/dev/null; then
        dnf remove -y "$cmd"
      elif command -v yum &>/dev/null; then
        yum remove -y "$cmd"
      else
        print_msg error "$(printf "$ERROR_INSTALL_COMMAND_NOT_SUPPORTED" "$cmd")"
      fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
      if command -v brew &>/dev/null; then
        brew uninstall "$cmd"
      else
        print_msg error "$ERROR_HOMEBREW_MISSING"
      fi
    else
      print_msg error "$(printf "$ERROR_OS_NOT_SUPPORTED" "$cmd")"
    fi
  done

  print_msg success "$SUCCESS_COMMANDS_UNINSTALL_DONE"
}




# ============================================
# 🕒 exit_after_10s – Exit script after 10 second
# ============================================
exit_after_10s() {
  local seconds=10

  echo ""
  local formatted_exit_msg
  formatted_exit_msg=$(printf "$IMPORTANT_EXIT_AFTER_SECS" "$seconds")
  print_msg important "$formatted_exit_msg"

  for ((i = seconds; i > 0; i--)); do
    echo -ne "⏳ Exiting after $i seconds...   \r"
    sleep 1
  done

  echo -e "\n🚪 Exiting..."

  if [[ "$OSTYPE" == "darwin"* ]]; then
    exit 0
  else
    # Nếu là login shell (có thể logout), thì dùng logout
    if shopt -q login_shell; then
      logout
    else
      exit 0
    fi
  fi
}