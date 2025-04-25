# =====================================
# 🧠 core_version_management.sh – Version Utilities (Refactored to use .config.json)
# =====================================

# === Get core channel from config JSON
core_channel_get() {
  json_get_value '.core.channel'
}

# === Get current version from config JSON
core_version_get_current() {
  local channel
  channel="$(core_channel_get)"

  if [[ "$channel" == "dev" ]]; then
    debug_log "[core_version_get_current] Channel is dev → version=dev"
    core_set_installed_version "dev"
    echo "dev"
    return
  fi

  local version
  version="$(core_get_installed_version)"

  if [[ -n "$version" && "$version" != "null" ]]; then
    debug_log "[core_version_get_current] Current version (from config): $version"
    echo "$version"
  else
    print_msg warning "$WARNING_VERSION_NOT_FOUND"
    local latest_version
    latest_version="$(core_version_get_latest 2>/dev/null)" # tránh lỗi màu hóa
    if [[ -n "$latest_version" ]]; then
      core_set_installed_version "$latest_version"
      print_msg info "$INFO_VERSION_FILE_RESTORED"
      echo "$latest_version"
    else
      print_msg error "$ERROR_FETCH_LATEST_VERSION_FAILED"
      debug_log
      echo "0.0.0"
    fi
  fi
}

# === Get latest version from remote GitHub (main/dev based on channel)
core_version_get_latest() {
  local channel version_url latest_version

  channel="$(core_channel_get)"

  if [[ "$channel" == "official" ]]; then
    version_url="https://raw.githubusercontent.com/thachpn165/wp-docker/refs/heads/main/src/version.txt"
  elif [[ "$channel" == "nightly" ]]; then
    version_url="https://raw.githubusercontent.com/thachpn165/wp-docker/refs/heads/dev/src/version.txt"
  elif [[ "$channel" == "dev" ]]; then
    debug_log "[core_version_get_latest] Channel is dev → skip fetching"
    echo "dev"
    return 0
  else
    print_msg error "❌ Invalid core channel in config: $channel"
    return 1
  fi

  latest_version=$(curl -fsSL "$version_url" | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+(-[a-z0-9]+)*(\+[0-9]+)?' | head -n1)

  debug_log "[core_version_get_latest] Channel       : $channel"
  debug_log "[core_version_get_latest] Version URL   : $version_url"
  debug_log "[core_version_get_latest] Latest Ver    : $latest_version"

  echo "$latest_version"
}

core_version_compare() {
  local v1="${1#v}"
  local v2="${2#v}"

  # Strip build metadata
  v1="${v1%%+*}"
  v2="${v2%%+*}"

  # Detect pre-release (contains -), add "-stable" if missing
  [[ "$v1" != *-* ]] && v1="${v1}-stable"
  [[ "$v2" != *-* ]] && v2="${v2}-stable"

  if [[ "$v1" == "$v2" ]]; then
    echo "equal"
    return 0
  fi

  local sorted
  sorted=$(printf "%s\n%s" "$v1" "$v2" | sort -V | head -n1)

  if [[ "$sorted" == "$v1" ]]; then
    echo "older" # nghĩa là $v1 < $v2
  else
    echo "newer" # nghĩa là $v1 > $v2
  fi

  return 0
}

# === Get download URL based on channel (main/dev)
core_get_download_url() {
  local channel repo_tag zip_name zip_url

  channel="$(core_channel_get)"
  zip_name=${ZIP_NAME:-"wp-docker.zip"}

  if [[ "$channel" == "official" ]]; then
    repo_tag="latest"
  elif [[ "$channel" == "nightly" ]]; then
    repo_tag="nightly"
  elif [[ "$channel" == "dev" ]]; then
    debug_log "[core_get_download_url] Dev channel → skip download"
    return 1
  else
    print_msg error "❌ Invalid core channel: $channel"
    return 1
  fi

  zip_url="https://github.com/thachpn165/wp-docker/releases/download/$repo_tag/$zip_name"
  debug_log "[core_get_download_url] Download URL: $zip_url"
  echo "$zip_url"
}

# =============================================
# 🚀 core_version_update_latest: Update WP Docker to the latest version
# =============================================
# Behavior:
#   - Check for a new version (except when --force is passed)
#   - Prompt user to confirm update
#   - Download and extract the latest release
#   - Sync updated files (excluding: sites/, archives/, logs/)
#   - Execute upgrade script if exists
#   - Show success message after update
#
# Usage:
#   core_version_update_latest [--force]
# =============================================
core_version_update_latest() {
  local latest_version installed_version channel upgrade_script
  local force force_update
  force=$(_parse_params "--force" "$@")

  if [[ "$force" == "1" ]]; then
    force_update="true"
  else
    force_update="false"
  fi

  # Get current release channel
  channel="$(core_channel_get)"

  # Get latest and current installed version
  latest_version=$(core_version_get_latest)
  installed_version=$(core_version_get_current)

  debug_log "Installed version: $installed_version"
  debug_log "Latest version: $latest_version"
  debug_log "Channel: $channel"
  debug_log "Force update: $force_update"

  if [[ "$force_update" != "true" && "$latest_version" == "$installed_version" ]]; then
    print_msg info "$INFO_CORE_VERSION_LATEST: $installed_version"
    print_msg tip "$TIP_CORE_ALREADY_UP_TO_DATE"
    return 0
  fi

  # Prompt user to confirm update
  print_msg step "$INFO_UPDATE_PROMPT: $latest_version"
  local confirm_update
  confirm_update=$(get_input_or_test_value "$PROMPT_UPDATE_CONFIRMATION ($latest_version) (yes/no): " "no")

  if [[ "$confirm_update" != "yes" ]]; then
    print_msg cancel "$CANCEL_CORE_UPDATE"
    return 0
  fi

  # Download the latest release zip file
  core_version_download_latest

  local temp_zip="/tmp/wp-docker.zip"
  local temp_dir="/tmp/wp-docker"

  # Verify zip exists
  if [[ ! -f "$temp_zip" ]]; then
    print_msg error "$MSG_NOT_FOUND : $temp_zip"
    return 1
  fi

  # Extract the zip file
  mkdir -p "$temp_dir"
  print_msg step "$INFO_UNPACKING_ZIP"
  unzip -q "$temp_zip" -d "$temp_dir" || {
    print_msg error "$ERROR_UNPACK_FAILED"
    return 1
  }

  # Sync source to INSTALL_DIR
  print_msg progress "$STEP_EXTRACT_AND_UPDATE"
  rsync -a --exclude='sites/' --exclude='archives/' --exclude='logs/' "$temp_dir/" "$INSTALL_DIR/"
  if [[ $? -ne 0 ]]; then
    print_msg error "$ERROR_SYNC_FAILED"
    return 1
  fi

  # Clean up temp files
  remove_directory "$temp_dir"
  remove_file "$temp_zip"

  # Save new installed version
  core_set_installed_version "$latest_version"

  # Run upgrade script if available
  if [[ "$channel" == "dev" ]]; then
    upgrade_script="$BASE_DIR/upgrade/dev-upgrade.sh"
  else
    upgrade_script="$BASE_DIR/upgrade/${latest_version}.sh"
  fi

  if [[ -f "$upgrade_script" && -x "$upgrade_script" ]]; then
    print_msg step "🚀 Running upgrade script: $(basename "$upgrade_script")"
    bash "$upgrade_script" || print_msg warning "⚠️ Upgrade script exited with non-zero status."
  else
    debug_log "No upgrade script found for version: $latest_version"
  fi

  # Final message
  print_msg success "$SUCCESS_CORE_UPDATED"

}

# ============================================
# 🧠 core_version_display – Display version info
# ============================================

core_version_display() {
  # Lấy phiên bản hiện tại từ .config.json
  local version_local
  version_local=$(core_version_get_current)

  # Lấy phiên bản mới nhất từ GitHub
  local version_remote
  version_remote=$(core_version_get_latest)
  echo ""
  # Hiển thị phiên bản hiện tại và mới nhất
  print_msg sub-label "$INFO_CORE_VERSION_CURRENT: $version_local"
  print_msg sub-label "$INFO_CORE_VERSION_LATEST: $version_remote"
  echo ""
  compare_result=$(core_version_compare "$version_local" "$version_remote")

  if [[ "$compare_result" == "older" ]]; then
    print_msg warning "$(printf "$WARNING_CORE_VERSION_NEW_AVAILABLE" "$version_local" "$version_remote")"
  else
    print_msg success "$SUCCESS_CORE_IS_LATEST"
  fi
}

core_version_download_latest() {
  local channel
  channel="$(core_channel_get)"

  # Xác định tag cho từng channel
  local repo_tag
  if [[ "$channel" == "official" ]]; then
    repo_tag="$OFFICIAL_REPO_TAG"
  elif [[ "$channel" == "nightly" ]]; then
    repo_tag="$NIGHTLY_REPO_TAG"
  elif [[ "$channel" == "dev" ]]; then
    debug_log "[core_version_download_latest] Channel is dev → skip downloading"
    echo "dev"
    return 0
  else
    print_msg error "❌ Invalid core channel: $channel"
    return 1
  fi

  local zip_url
  zip_url=$(core_get_download_url "$channel")
  debug_log "[core_version_download_latest] Download URL: $zip_url"

  # Tải về file zip tương ứng với channel vào thư mục /tmp/
  local temp_zip="/tmp/wp-docker.zip"
  if ! network_check_http "$zip_url"; then
    print_msg error "$ERROR_CORE_ZIP_URL_NOT_REACHABLE: $zip_url"
    return 1
  fi
  curl -fsSL "$zip_url" -o "$temp_zip"
  if [[ $? -ne 0 ]]; then
    print_msg error "$ERROR_DOWNLOAD_FAILED"
    return 1
  fi

  print_msg success "$SUCCESS_WP_DOCKER_ZIP_DOWNLOADED"
}
