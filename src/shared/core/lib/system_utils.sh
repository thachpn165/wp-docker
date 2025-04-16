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

  if ! [[ "$editor_index" =~ ^[0-9]+$ ]] || (( editor_index < 1 || editor_index > ${#AVAILABLE_EDITORS[@]} )); then
    print_msg warning "$WARNING_EDITOR_INVALID_SELECT"
    EDITOR_CMD="nano"
  else
    EDITOR_CMD="${AVAILABLE_EDITORS[$((editor_index - 1))]}"
  fi

  print_msg info "$(printf "$INFO_EDITOR_USAGE_GUIDE" "$EDITOR_CMD")"

  confirm=$(get_input_or_test_value "$PROMPT_CONFIRM_EDITOR" "${TEST_CONFIRM_EDITOR:-y}")
  if [[ "$confirm" =~ ^[Nn]$ ]]; then
    print_msg warning "$WARNING_EDITOR_CANCELLED"
    return 1
  fi

  return 0
}

# ============================================
# 🧪 check_required_commands – Ensure required commands are installed
# ============================================
# Description:
#   - Verifies availability of CLI tools like docker, jq, curl, unzip, etc.
#   - Installs missing ones depending on OS.
#
# Globals:
#   OSTYPE
#   WARNING_COMMAND_NOT_FOUND
#   SUCCESS_COMMAND_AVAILABLE
#   ERROR_INSTALL_COMMAND_NOT_SUPPORTED
#   ERROR_OS_NOT_SUPPORTED
#   WARNING_HOMEBREW_MISSING
check_required_commands() {
  print_msg info "$INFO_CHECKING_COMMANDS"

  required_cmds=(docker "docker compose" nano rsync curl tar gzip unzip jq openssl crontab jq dialog)

  for cmd in "${required_cmds[@]}"; do
    if [[ "$cmd" == "docker compose" ]]; then
      if docker compose version &> /dev/null; then
        print_msg success "$SUCCESS_COMMAND_AVAILABLE: $cmd"
        continue
      else
        print_msg warning "$WARNING_COMMAND_NOT_FOUND: $cmd"
        install_docker_compose
        continue
      fi
    fi

    if ! command -v "$(echo "$cmd" | awk '{print $1}')" &> /dev/null; then
      print_msg warning "$(printf '%s' "$WARNING_COMMAND_NOT_FOUND" "$cmd")"

      if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt &> /dev/null; then
          apt update -y && apt install -y "$(echo "$cmd" | awk '{print $1}')"
        elif command -v yum &> /dev/null; then
          yum install -y "$(echo "$cmd" | awk '{print $1}')"
        elif command -v dnf &> /dev/null; then
          dnf install -y "$(echo "$cmd" | awk '{print $1}')"
        else
          print_msg error "$(printf '%s' "$ERROR_INSTALL_COMMAND_NOT_SUPPORTED" "$cmd")"
        fi
      elif [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v brew &> /dev/null; then
          print_msg warning "$WARNING_HOMEBREW_MISSING"
          /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install "$(echo "$cmd" | awk '{print $1}')"
      else
        print_msg error "$(printf '%s' "$ERROR_OS_NOT_SUPPORTED" "$cmd")"
      fi
    else
      print_msg success "$(printf '%s' "$SUCCESS_COMMAND_AVAILABLE" "$cmd")"
    fi
  done
}
uninstall_required_commands() {
  print_msg info "🧹 Uninstalling required commands..."

  required_cmds=(jq dialog)

  for cmd in "${required_cmds[@]}"; do
    cmd_name="$(echo "$cmd" | awk '{print $1}')"

    if ! command -v "$cmd_name" &>/dev/null; then
      print_msg skip "⏩ Command not installed: $cmd_name"
      continue
    fi

    print_msg warning "⚠️ Attempting to uninstall: $cmd_name"

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
      if command -v apt &>/dev/null; then
        apt remove -y "$cmd_name"
      elif command -v yum &>/dev/null; then
        yum remove -y "$cmd_name"
      elif command -v dnf &>/dev/null; then
        dnf remove -y "$cmd_name"
      else
        print_msg error "❌ Unsupported package manager for: $cmd_name"
      fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
      if command -v brew &>/dev/null; then
        brew uninstall "$cmd_name"
      else
        print_msg error "❌ Homebrew not found. Cannot uninstall: $cmd_name"
      fi
    else
      print_msg error "❌ Unsupported OS: $OSTYPE"
    fi
  done

  print_msg success "✅ Uninstall process completed."
}

# ============================================
# 🔗 check_and_add_alias – Add wpdocker CLI alias to shell config
# ============================================
# Description:
#   - Adds alias for `wpdocker` to `.bashrc` or `.zshrc`.
#   - Reloads shell config after writing alias.
#
# Globals:
#   INSTALL_DIR
#   SHELL
check_and_add_alias() {
  local shell_config cli_dir_abs alias_line

  cli_dir_abs=$(realpath "$INSTALL_DIR/shared/bin")
  alias_line="alias wpdocker=\"bash $cli_dir_abs/wpdocker\""

  if [[ "$SHELL" == *"zsh"* ]]; then
    shell_config="$HOME/.zshrc"
  else
    shell_config="$HOME/.bashrc"
  fi

  if grep -q "alias wpdocker=" "$shell_config"; then
    echo "🧹 Removing existing alias from $shell_config..."
    sed -i.bak '/alias wpdocker=/d' "$shell_config"
  fi

  echo "$alias_line" >> "$shell_config"
  echo "✅ Added alias for wpdocker to $shell_config"

  if [[ "$SHELL" == *"zsh"* ]]; then
    echo "🔄 Reloading .zshrc..."
    source "$HOME/.zshrc"
  elif [[ "$SHELL" == *"bash"* ]]; then
    echo "🔄 Reloading .bashrc..."
    source "$HOME/.bashrc"
  else
    echo "⚠️ Unsupported shell. Please reload shell config manually."
  fi
}