# ==================================================
# File: system_utils.sh
# Description: This script contains utility functions for system and CLI management, 
#              including resource detection, timezone setup, editor selection, 
#              package updates, and command management.
# Functions:
#   - get_total_ram: Retrieve total RAM in MB.
#       Parameters: None
#       Returns: Total RAM (in MB) as an integer.
#   - get_total_cpu: Retrieve the number of CPU cores.
#       Parameters: None
#       Returns: Total number of CPU cores.
#   - sedi: Cross-platform `sed` wrapper for macOS and Linux.
#       Parameters: All parameters passed directly to the `sed` command.
#       Globals: OSTYPE
#   - setup_timezone: Ensure system timezone is set to Vietnam.
#       Parameters: None
#       Globals: OSTYPE, WARNING_TIMEZONE_NOT_VIETNAM, SUCCESS_TIMEZONE_SET
#   - choose_editor: Prompt user to select a CLI text editor.
#       Parameters: None
#       Globals: PROMPT_SELECT_EDITOR, PROMPT_CONFIRM_EDITOR, INFO_CHECKING_EDITORS, 
#                INFO_AVAILABLE_EDITORS, INFO_EDITOR_USAGE_GUIDE, WARNING_EDITOR_INVALID_SELECT, 
#                WARNING_EDITOR_CANCELLED, DEBUG_MODE
#       Returns: 0 if an editor was selected, 1 if canceled or invalid input.
#   - core_system_update_os_packages: Update system packages based on OS type.
#       Parameters: None
#       Behavior: Detects OS type and runs appropriate update commands.
#   - core_system_check_required_commands: Ensure required commands are installed.
#       Parameters: None
#       Globals: CORE_REQUIRED_COMMANDS, OSTYPE
#   - core_system_uninstall_required_commands: Uninstall system commands based on JSON configuration.
#       Parameters: None
#       Globals: CORE_REQUIRED_COMMANDS, OSTYPE
#   - exit_after_10s: Exit the script after 10 seconds.
#       Parameters: None
#       Globals: OSTYPE
# ==================================================

get_total_ram() {
  if command -v free >/dev/null 2>&1; then
    free -m | awk '/^Mem:/{print $2}'
  else
    sysctl -n hw.memsize | awk '{print $1 / 1024 / 1024}'
  fi
}

get_total_cpu() {
  if command -v nproc >/dev/null 2>&1; then
    nproc
  else
    sysctl -n hw.ncpu
  fi
}

sedi() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

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

core_system_update_os_packages() {
  echo "🔄 Updating system packages..."

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

  if [[ "$OS_NAME" == "CentOS" && "$OS_VERSION_ID" == "8" ]] ||
    [[ "$OS_NAME" == "AlmaLinux" && "$OS_VERSION_ID" == "8" ]]; then
    dnf update --nogpgcheck -y || yum update --nogpgcheck -y
  elif [[ "$OS_NAME" == "Ubuntu" ]]; then
    apt update -y && apt upgrade -y
  elif command -v apt &>/dev/null; then
    apt update -y && apt upgrade -y
  elif command -v dnf &>/dev/null; then
    dnf update -y
  elif command -v yum &>/dev/null; then
    yum update -y
  else
    echo "⚠️ Unsupported operating system: ${OS_NAME}"
    return 1
  fi

  echo "✅ System update completed."
  return 0
}

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
    if shopt -q login_shell; then
      logout
    else
      exit 0
    fi
  fi
}