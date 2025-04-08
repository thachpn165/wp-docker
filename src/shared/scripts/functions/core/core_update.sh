# =====================================
# 🔄 core_update_system – Update WP Docker from GitHub Releases
# =====================================
core_update_system() {
  local force_update=false
  for arg in "$@"; do
    if [[ "$arg" == "--force" ]]; then
      force_update=true
    fi
  done

  # === Nếu DEV_MODE=true thì cảnh báo và không cho update
  if [[ "$DEV_MODE" == "true" ]]; then
    local version_local version_remote
    version_local="$(core_get_current_version)"
    version_remote="$(core_get_latest_version)"
    print_msg info "$INFO_CORE_VERSION_CURRENT: $version_local"
    print_msg info "$INFO_CORE_VERSION_LATEST: $version_remote"
    print_msg warning "$WARNING_DEV_MODE_NO_UPDATE"
    return 0
  fi

  local channel version_local version_remote zip_url zip_name
  channel="$(core_get_channel)"
  version_local="$(core_get_current_version)"
  version_remote="$(core_get_latest_version)"
  zip_url="$(core_get_download_url)"
  zip_name="wp-docker.zip"

  debug_log "Current version         : $version_local"
  debug_log "Latest version [$channel]: $version_remote"
  debug_log "Force update?           : $force_update"

  core_compare_versions "$version_local" "$version_remote"
  local cmp_result=$?

  if [[ "$cmp_result" -ne 2 ]]; then
    if [[ "$force_update" == false ]]; then
      print_msg skip "$SKIP_CORE_ALREADY_LATEST [$version_local]"
      return 0
    else
      print_msg warning "$WARNING_FORCE_UPDATE_SAME_VERSION"
    fi
  fi

  print_msg important "$INFO_UPDATING_CORE: $version_local ➔ $version_remote"
  get_user_confirmation "$CONFIRM_UPDATE_CORE"

  local tmp_dir tmp_zip backup_dir
  tmp_dir="$(mktemp -d)"
  tmp_zip="$tmp_dir/$zip_name"
  print_msg info "$INFO_DOWNLOADING_CORE_UPDATE"

  if ! curl -L "$zip_url" -o "$tmp_zip"; then
    print_msg error "$ERROR_DOWNLOAD_FAILED: $zip_url"
    rm -rf "$tmp_dir"
    return 1
  fi

  print_msg step "$STEP_EXTRACT_AND_UPDATE"
  unzip -q "$tmp_zip" -d "$tmp_dir"

  if [[ ! -d "$tmp_dir/src" ]]; then
    print_msg error "$ERROR_EXTRACT_FAILED"
    rm -rf "$tmp_dir"
    return 1
  fi

  backup_dir="${PROJECT_DIR}/.backup-$(date +%Y%m%d-%H%M%S)"
  mv "$PROJECT_DIR/src" "$backup_dir"
  mv "$tmp_dir/src" "$PROJECT_DIR/src"
  print_msg success "$SUCCESS_CORE_UPDATED"
  print_msg info "$INFO_BACKUP_OLD_SRC: $backup_dir"

  rm -rf "$tmp_dir"
  return 0
}