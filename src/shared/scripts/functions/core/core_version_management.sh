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
    latest_version="$(core_version_get_latest 2>/dev/null)"  # tránh lỗi màu hóa
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

# === Update to latest version
core_version_update_latest() {
  local latest_version
  local channel

  # Lấy giá trị channel từ config
  channel="$(core_channel_get)"

  # Hiển thị phiên bản mới nhất thông qua core_version_get_latest
  latest_version=$(core_version_get_latest)
  print_msg info "$INFO_CORE_VERSION_LATEST: $latest_version"

  # Yêu cầu người dùng xác nhận có muốn cập nhật phiên bản mới không
  print_msg step "$INFO_UPDATE_PROMPT: $latest_version"
  local confirm_update
  confirm_update=$(get_input_or_test_value "$PROMPT_UPDATE_CONFIRMATION ($latest_version) (yes/no): " "no")

  if [[ "$confirm_update" != "yes" ]]; then
    print_msg cancel "$CANCEL_CORE_UPDATE"
    return 0
  fi

  # Gọi hàm để tải phiên bản mới nhất về
  core_version_download_latest

  # Đường dẫn tạm lưu file zip
  local temp_zip="/tmp/wp-docker.zip"
  
  # Kiểm tra nếu file zip tồn tại
  if [[ ! -f "$temp_zip" ]]; then
    print_msg error "$MSG_NOT_FOUND : $temp_zip"
    return 1
  fi

  # Tạo thư mục tạm để giải nén
  local temp_dir="/tmp/wp-docker"
  mkdir -p "$temp_dir"

  # Giải nén tập tin zip vào thư mục tạm
  print_msg step "$INFO_UNPACKING_ZIP"
  unzip -q "$temp_zip" -d "$temp_dir" || {
    print_msg error "$ERROR_UNPACK_FAILED"
    return 1
  }

  # Đồng bộ mã nguồn vào INSTALL_DIR (thư mục cài đặt)
  print_msg progress "$STEP_EXTRACT_AND_UPDATE"
  rsync -a --exclude='sites/' --exclude='archives/' --exclude='logs/' "$temp_dir/" "$INSTALL_DIR/"
  if [[ $? -ne 0 ]]; then
    print_msg error "$ERROR_SYNC_FAILED"
    stop_loading
    return 1
  fi
  stop_loading

  # Sau khi đồng bộ, xóa tập tin zip và thư mục tạm
  remove_directory "$temp_dir"
  remove_file "$temp_zip"

  # Cập nhật lại phiên bản đã cài đặt trong config
  core_set_installed_version "$latest_version"

  # In thông báo thành công
  print_msg success "$SUCCESS_CORE_UPDATED"
  exit_after_10s
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

  # Hiển thị phiên bản hiện tại và mới nhất
  print_msg info "$INFO_CORE_VERSION_CURRENT: $version_local"
  print_msg info "$INFO_CORE_VERSION_LATEST: $version_remote"

  # Kiểm tra phiên bản và cảnh báo nếu có phiên bản mới
  core_version_compare "$version_local" "$version_remote"
  local result=$?

  if [[ "$result" -eq 2 ]]; then
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
