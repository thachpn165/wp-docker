# ==============================================================================
# 🎛 core_channel.sh – Functions to manage and switch between release channels
# ==============================================================================
# Description:
#   Provides logic to change the system's release channel (official, nightly, dev),
#   update installed version information accordingly, and prompt the user interactively.
#
# Functions:
#   - core_channel_switch: Switch to a specified channel and update config/version.
#   - core_channel_switch_prompt: Prompt the user to choose a release channel.
#
# Dependencies:
#   - json_set_value, core_channel_get, core_set_installed_version,
#     core_version_get_latest, core_version_update_latest, get_input_or_test_value

# ================================================
# 🔁 core_channel_switch – Change release channel
# ================================================
# Description:
#   Switches to the specified release channel and updates the installed version.
#
# Parameters:
#   $1 - new_channel (required): The channel to switch to (e.g., official, nightly, dev)
#
# Globals:
#   - Updates .core.channel and .core.installed_version in JSON config
#
# Behavior:
#   - If new_channel is 'dev', sets installed_version to 'dev'
#   - Otherwise, fetches and updates the latest version
#   - Prints status messages and returns 0 on success, 1 on error
core_channel_switch() {
  local new_channel="$1"

  if [[ -z "$new_channel" ]]; then
    print_msg error "$ERROR_MISSING_PARAM: --new_channel"
    return 1
  fi

  local current_channel
  current_channel=$(core_channel_get)

  # Nếu kênh mới giống kênh hiện tại, không cần làm gì
  if [[ "$new_channel" == "$current_channel" ]]; then
    print_msg info "$INFO_CHANNEL_ALREADY_SET: $new_channel"
    return 0
  fi

  # Cập nhật channel mới trong config
  json_set_value ".core.channel" "$new_channel"
  print_msg info "$INFO_CHANNEL_CHANGED: $current_channel → $new_channel"

  # Nếu là kênh 'dev', không cần tải lại phiên bản, chỉ cần set lại installed_version là "dev"
  if [[ "$new_channel" == "dev" ]]; then
    core_set_installed_version "dev"
    print_msg info "$INFO_DEV_CHANNEL_SELECTED"
    return 0
  fi

  # Nếu không phải dev, tải phiên bản mới từ remote
  local latest_version
  latest_version=$(core_version_get_latest)

  if [[ -z "$latest_version" ]]; then
    print_msg error "$ERROR_FETCH_LATEST_VERSION_FAILED"
    return 1
  fi

  # Cập nhật lại installed_version với phiên bản mới
  core_set_installed_version "$latest_version"
  print_msg success "$SUCCESS_NEW_VERSION_INSTALLED: $latest_version"

  # Cập nhật mã nguồn mới nhất từ remote
  core_version_update_latest

  return 0
}

# ======================================================
# 🧭 core_channel_switch_prompt – Prompt for channel switch
# ======================================================
# Description:
#   Prompts the user to select a release channel and switches to it.
#
# Globals:
#   - PROMPT_CHANNEL_SELECT
#   - MSG_CORE_CHANNEL_AVAILABLE
#   - ERROR_SELECT_OPTION_INVALID
#
# Behavior:
#   - Displays list of available channels
#   - Gets user input
#   - Calls core_channel_switch with the selected value
core_channel_switch_prompt() {
  # Available channels
  local channels=("official" "nightly" "dev")

  # Prompt user to select a channel
  print_msg info "$MSG_CORE_CHANNEL_AVAILABLE: "
  for i in "${!channels[@]}"; do
    echo "  $((i+1)). ${channels[$i]}"
  done

  local choice
  choice=$(get_input_or_test_value "$PROMPT_CHANNEL_SELECT [1-${#channels[@]}]: " "2")

  # Validate input and call core_channel_switch with the selected channel
  if [[ "$choice" =~ ^[0-9]+$ && "$choice" -ge 1 && "$choice" -le ${#channels[@]} ]]; then
    local selected_channel="${channels[$((choice - 1))]}"
    core_channel_switch "$selected_channel"
  else
    print_msg error "$ERROR_SELECT_OPTION_INVALID"
    return 1
  fi
}