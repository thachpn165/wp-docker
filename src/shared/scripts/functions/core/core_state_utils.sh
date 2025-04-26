#!/bin/bash
# ==================================================
# File: core_state_utils.sh
# Description: Functions to manage core state utilities, including retrieving and setting 
#              the installed version, managing update channels, and checking development mode.
# Functions:
#   - core_get_installed_version: Get the currently installed WP Docker version.
#       Parameters: None.
#   - core_set_installed_version: Save the installed version to the configuration.
#       Parameters:
#           $1 - version: The version string to save.
#   - core_channel_get: Get the current update channel.
#       Parameters: None.
#   - core_set_channel: Set the update channel in the configuration.
#       Parameters:
#           $1 - channel: The update channel to set (official, nightly, dev).
#   - core_is_dev_mode: Check if the current channel is set to "dev".
#       Parameters: None.
# ==================================================

core_get_installed_version() {
  json_get_value '.core.installed_version'
}

core_set_installed_version() {
  local version="$1"
  json_set_value '.core.installed_version' "$version"
}

core_channel_get() {
  json_get_value '.core.channel'
}

core_set_channel() {
  local channel="$1"
  if [[ "$channel" != "official" && "$channel" != "nightly" && "$channel" != "dev" ]]; then
    print_msg error "Invalid channel: $channel"
    print_msg error "$ERROR_CORE_CHANNEL_INVALID"
    return 1
  fi
  json_set_value '.core.channel' "$channel"
}

core_is_dev_mode() {
  local channel
  channel="$(core_channel_get)"
  [[ "$channel" == "dev" ]]
}