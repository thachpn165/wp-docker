#!/bin/bash
# ==================================================
# File: core_channel.sh
# Description: Functions to manage and switch between release channels, including updating 
#              the system's release channel (official, nightly, dev) and installed version.
# Functions:
#   - core_channel_switch: Switch to a specified channel and update config/version.
#       Parameters:
#           $1 - new_channel: The channel to switch to (e.g., official, nightly, dev).
#   - core_channel_switch_prompt: Prompt the user to choose a release channel.
#       Parameters: None.
# ==================================================

core_channel_switch() {
  local new_channel="$1"

  if [[ -z "$new_channel" ]]; then
    print_msg error "$ERROR_MISSING_PARAM: --new_channel"
    return 1
  fi

  local current_channel
  current_channel=$(core_channel_get)

  if [[ "$new_channel" == "$current_channel" ]]; then
    print_msg info "$INFO_CHANNEL_ALREADY_SET: $new_channel"
    return 0
  fi

  json_set_value ".core.channel" "$new_channel"
  print_msg info "$INFO_CHANNEL_CHANGED: $current_channel → $new_channel"

  if [[ "$new_channel" == "dev" ]]; then
    core_set_installed_version "dev"
    print_msg info "$INFO_DEV_CHANNEL_SELECTED"
    return 0
  fi

  local latest_version
  latest_version=$(core_version_get_latest)

  if [[ -z "$latest_version" ]]; then
    print_msg error "$ERROR_FETCH_LATEST_VERSION_FAILED"
    return 1
  fi

  core_set_installed_version "$latest_version"
  print_msg success "$SUCCESS_NEW_VERSION_INSTALLED: $latest_version"

  core_version_update_latest

  return 0
}

core_channel_switch_prompt() {
  local channels=("official" "nightly" "dev")

  print_msg info "$MSG_CORE_CHANNEL_AVAILABLE: "
  for i in "${!channels[@]}"; do
    echo "  $((i+1)). ${channels[$i]}"
  done

  local choice
  choice=$(get_input_or_test_value "$PROMPT_CHANNEL_SELECT [1-${#channels[@]}]: " "2")

  if [[ "$choice" =~ ^[0-9]+$ && "$choice" -ge 1 && "$choice" -le ${#channels[@]} ]]; then
    local selected_channel="${channels[$((choice - 1))]}"
    core_channel_switch "$selected_channel"
  else
    print_msg error "$ERROR_SELECT_OPTION_INVALID"
    return 1
  fi
}