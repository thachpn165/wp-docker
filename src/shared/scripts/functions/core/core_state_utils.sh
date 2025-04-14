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
