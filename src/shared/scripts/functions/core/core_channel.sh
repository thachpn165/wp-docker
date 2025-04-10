# Hàm chuyển đổi kênh và cập nhật phiên bản
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

# Function to prompt the user to select a channel and switch to it
core_channel_switch_prompt() {
  # Available channels
  local channels=("official" "nightly" "dev")

  # Prompt user to select a channel
  echo -e "\n📡 Available Channels:"
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