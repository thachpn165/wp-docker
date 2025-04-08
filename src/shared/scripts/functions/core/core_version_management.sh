# =====================================
# 🧠 core_version_management.sh – Version Utilities (Refactored)
# =====================================

# === Get current version from local file
core_get_current_version() {
  local version_file="$PROJECT_DIR/version.txt"

  if [[ -f "$version_file" ]]; then
    cat "$version_file"
  else
    print_msg warning "$WARNING_VERSION_FILE_NOT_FOUND"
    local latest_version
    latest_version="$(core_get_latest_version)"
    if [[ -n "$latest_version" ]]; then
      echo "$latest_version" > "$version_file"
      print_msg info "$(printf "$INFO_VERSION_FILE_RESTORED" "$version_file")"
      echo "$latest_version"
    else
      print_msg error "$ERROR_FETCH_LATEST_VERSION_FAILED"
      echo "0.0.0"
    fi
  fi
}

# === Get latest version from remote GitHub (main/dev based on channel)
core_get_latest_version() {
  local channel version_url latest_version

  channel="$(core_get_channel)"

  if [[ "$channel" == "official" ]]; then
    version_url="https://raw.githubusercontent.com/thachpn165/wp-docker/refs/heads/main/src/version.txt"
  elif [[ "$channel" == "nightly" ]]; then
    version_url="https://raw.githubusercontent.com/thachpn165/wp-docker/refs/heads/dev/src/version.txt"
  else
    print_msg error "❌ Invalid CORE_CHANNEL: $channel"
    return 1
  fi

  latest_version=$(curl -fsSL "$version_url" | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+(-[a-z0-9]+)*(\+[0-9]+)?' | head -n1)

  debug_log "[core_get_latest_version] Channel: $channel"
  debug_log "[core_get_latest_version] Version URL: $version_url"
  debug_log "[core_get_latest_version] Latest version: $latest_version"

  echo "$latest_version"
}

# === Compare versions: returns 0 if equal, 1 if v1 > v2, 2 if v1 < v2
core_compare_versions() {
  local v1=$(echo "$1" | sed 's/^v//')
  local v2=$(echo "$2" | sed 's/^v//')

  if [[ "$v1" == "$v2" ]]; then return 0; fi

  local sorted
  sorted=$(printf "%s\n%s" "$v1" "$v2" | sort -V | head -n1)
  if [[ "$sorted" == "$v1" ]]; then
    return 2  # $1 < $2
  else
    return 1  # $1 > $2
  fi
}

# === Get core channel from .env
core_get_channel() {
  local env_file="$PROJECT_DIR/.env"
  fetch_env_variable "$env_file" "CORE_CHANNEL" | tr -d '"'
}

# === Get download URL based on channel (main/dev)
core_get_download_url() {
  local channel repo_tag zip_name zip_url

  channel="$(core_get_channel)"
  zip_name="wp-docker.zip"

  if [[ "$channel" == "official" ]]; then
    repo_tag="latest"
  elif [[ "$channel" == "nightly" ]]; then
    repo_tag="nightly"
  else
    print_msg error "❌ Invalid CORE_CHANNEL: $channel"
    return 1
  fi

  zip_url="https://github.com/thachpn165/wp-docker/releases/download/$repo_tag/$zip_name"
  echo "$zip_url"
}

core_display_version() {
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

# === Backup current src directory
core_backup_current_src() {
  local timestamp
  timestamp="$(date +%Y%m%d-%H%M%S)"
  local backup_dir="${PROJECT_DIR}/.backup-${timestamp}"

  # Nếu có thư mục src → người dùng đang dùng dạng clone
  if [[ -d "$PROJECT_DIR/src" ]]; then
    mv "$PROJECT_DIR/src" "$backup_dir"
  else
    # Người dùng dùng bản build zip: backup toàn bộ nhưng loại trừ file .env và thư mục backup cũ
    mkdir -p "$backup_dir"
    rsync -a --exclude=".env" --exclude=".backup*" "$PROJECT_DIR/" "$backup_dir/"
  fi

  print_msg info "$INFO_BACKUP_OLD_SRC: $backup_dir"
}