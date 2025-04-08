# =====================================
# 🧾 core_display_version_logic – Hiển thị phiên bản hiện tại và mới nhất
# =====================================
core_display_version_logic() {
  local channel version_local version_remote

  channel="$(core_get_channel)"
  version_local="$(core_get_current_version)"
  version_remote="$(core_get_latest_version)"

  debug_log "[core_display_version_logic] Channel       : $channel"
  debug_log "[core_display_version_logic] Current ver   : $version_local"
  debug_log "[core_display_version_logic] Latest  ver   : $version_remote"

  # Kiểm tra lỗi fetch
  if [[ -z "$version_remote" ]]; then
    print_msg error "$(printf "$ERROR_VERSION_CHANNEL_FAILED_FETCH_LATEST" "$channel")"
    return 1
  fi

  print_msg info "$INFO_CORE_VERSION_CURRENT: $version_local"
  print_msg info "$INFO_CORE_VERSION_LATEST: $version_remote"

  core_compare_versions "$version_local" "$version_remote"
  local result=$?

  if [[ "$result" -eq 2 ]]; then
    print_msg warning "$(printf "$WARNING_CORE_VERSION_NEW_AVAILABLE" "$version_local" "$version_remote")"
  else
    print_msg success "$SUCCESS_CORE_IS_LATEST"
  fi
}