# ==================================================
# 🧠 System & CLI Utilities – Refactored for i18n
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

check_required_commands() {
  print_msg info "$INFO_CHECKING_COMMANDS"

  required_cmds=(docker "docker compose" nano rsync curl tar gzip unzip jq openssl crontab dialog)

  for cmd in "${required_cmds[@]}"; do
    if [[ "$cmd" == "docker compose" ]]; then
      if docker compose version &> /dev/null; then
        print_msg success "$(printf "$SUCCESS_COMMAND_AVAILABLE" "$cmd")"
        continue
      else
        print_msg warning "$(printf "$WARNING_COMMAND_NOT_FOUND" "$cmd")"
        install_docker_compose
        continue
      fi
    fi

    if ! command -v $(echo "$cmd" | awk '{print $1}') &> /dev/null; then
      print_msg warning "$(printf "$WARNING_COMMAND_NOT_FOUND" "$cmd")"

      if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt &> /dev/null; then
          apt update -y && apt install -y $(echo "$cmd" | awk '{print $1}')
        elif command -v yum &> /dev/null; then
          yum install -y $(echo "$cmd" | awk '{print $1}')
        elif command -v dnf &> /dev/null; then
          dnf install -y $(echo "$cmd" | awk '{print $1}')
        else
          print_msg error "$(printf "$ERROR_INSTALL_COMMAND_NOT_SUPPORTED" "$cmd")"
        fi
      elif [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v brew &> /dev/null; then
          print_msg warning "$WARNING_HOMEBREW_MISSING"
          /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install $(echo "$cmd" | awk '{print $1}')
      else
        print_msg error "$(printf "$ERROR_OS_NOT_SUPPORTED" "$cmd")"
      fi
    else
      print_msg success "$(printf "$SUCCESS_COMMAND_AVAILABLE" "$cmd")"
    fi
  done
}