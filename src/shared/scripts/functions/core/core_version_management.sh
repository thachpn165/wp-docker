# =====================================
# 🧠 core_version_management.sh – Version Utilities (Refactored to use .config.json)
# =====================================

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
    latest_version="$(core_version_get_latest 2>/dev/null)"  # tránh lỗi màu hóa
    if [[ -n "$latest_version" ]]; then
      core_set_installed_version "$latest_version"
      print_msg info "$(printf "$INFO_VERSION_FILE_RESTORED" "$JSON_CONFIG_FILE")"
      echo "$latest_version"
    else
      print_msg error "$ERROR_FETCH_LATEST_VERSION_FAILED"
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

# === Compare versions: returns 0 if equal, 1 if v1 > v2, 2 if v1 < v2
core_version_compare() {
  local v1="${1#v}"
  local v2="${2#v}"

  # Strip build metadata
  v1="${v1%%+*}"
  v2="${v2%%+*}"

  # Detect pre-release (contains -) and add "-stable" if không có
  [[ "$v1" != *-* ]] && v1="${v1}-stable"
  [[ "$v2" != *-* ]] && v2="${v2}-stable"

  if [[ "$v1" == "$v2" ]]; then return 0; fi

  local sorted
  sorted=$(printf "%s\n%s" "$v1" "$v2" | sort -V | head -n1)

  if [[ "$sorted" == "$v1" ]]; then
    return 2  # $1 < $2
  else
    return 1  # $1 > $2
  fi
}

# === Get core channel from config JSON
core_channel_get() {
  json_get_value '.core.channel'
}

# === Get download URL based on channel (main/dev)
core_get_download_url() {
  local channel repo_tag zip_name zip_url

  channel="$(core_channel_get)"
  zip_name="wp-docker.zip"

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

# === Display local and remote version
core_version_display_logic() {
  local channel version_local version_remote

  channel="$(core_get_channel)"
  version_local="$(core_get_current_version)"

  if [[ "$channel" == "dev" ]]; then
    print_msg info "$INFO_CORE_VERSION_CURRENT: $version_local"
    print_msg info "$INFO_CORE_VERSION_DEV_MODE"
    return 0
  fi

  version_remote="$(core_get_latest_version)"

  debug_log "[core_version_display] Channel       : $channel"
  debug_log "[core_version_display] Current ver   : $version_local"
  debug_log "[core_version_display] Latest  ver   : $version_remote"

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
core_version_display() {
  core_version_display_logic
}

# === Backup current src directory
core_backup_current_src() {
  local timestamp
  timestamp="$(date +%Y%m%d-%H%M%S)"
  local backup_dir="${PROJECT_DIR}/.backup-${timestamp}"

  if [[ -d "$PROJECT_DIR/src" ]]; then
    mv "$PROJECT_DIR/src" "$backup_dir"
  else
    mkdir -p "$backup_dir"
    rsync -a --exclude=".env" --exclude=".backup*" "$PROJECT_DIR/" "$backup_dir/"
  fi

  print_msg info "$INFO_BACKUP_OLD_SRC: $backup_dir"
}