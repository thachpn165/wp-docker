#!/bin/bash

# ==============================
# Core Version Management Logic
# ==============================

# === Function: Fetch environment variable from .env file ===
core_get_channel() {
  local env_file="${ENV_FILE:-$PROJECT_DIR/.env}"

  fetch_env_variable "$env_file" "CORE_CHANNEL"
}

# =====================================
# 🌐 core_get_download_url – Trả về URL tải phiên bản WP Docker theo channel
# =====================================
core_get_download_url() {
  local channel repo_tag zip_name zip_url

  channel="$(core_get_channel)"
  zip_name="wp-docker.zip"

  # Ánh xạ channel → release tag
  if [[ "$channel" == "official" ]]; then
    repo_tag="latest"
  elif [[ "$channel" == "nightly" ]]; then
    repo_tag="nightly"
  else
    print_msg error "❌ Invalid CORE_CHANNEL: $channel"
    return 1
  fi

  zip_url="$REPO_URL/releases/download/$repo_tag/$zip_name"
  echo "$zip_url"
}

# === Function: Cache the latest version with 12-hour expiration ===
core_version_cache() {
  local cache_file="$BASE_DIR/latest_version.txt"
  local cache_expiration=43200  # 12 hours in seconds

  if [[ -f "$cache_file" ]]; then
    local file_mod_time
    if [[ "$OSTYPE" == "darwin"* ]]; then
      file_mod_time=$(stat -f %m "$cache_file")
    else
      file_mod_time=$(stat -c %Y "$cache_file")
    fi

    local now=$(date +%s)
    local file_age=$((now - file_mod_time))

    if [[ $file_age -gt $cache_expiration ]]; then
      print_msg warning "$WARNING_CORE_CACHE_OUTDATED"
      local latest_version=$(curl -s "$CORE_LATEST_VERSION")
      echo "$latest_version" > "$cache_file"
    else
      latest_version=$(cat "$cache_file")
    fi
  else
    print_msg warning "$WARNING_CORE_CACHE_MISSING"
    local latest_version=$(curl -s "$CORE_LATEST_VERSION")
    echo "$latest_version" > "$cache_file"
  fi

  echo "$latest_version"
}

# === Function: Compare two versions ===
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

# === Function: Return latest version (from cache or GitHub) ===
core_get_version() {
  local version
  version=$(core_version_cache)
  echo "$version"
}

# === Function: Display current version and update status ===
core_display_version() {
  core_display_version_logic "$CORE_CHANNEL"
}

# === Function: Check and notify about new version (used in main menu) ===
core_check_for_update() {
  local current_version=$(cat "$BASE_DIR/version.txt")
  local latest_version=$(core_version_cache)

  core_compare_versions "$current_version" "$latest_version"
  local result=$?

  if [[ "$result" -eq 2 ]]; then
    printf "$WARNING_CORE_VERSION_NEW_AVAILABLE\n" "$current_version" "$latest_version"
    print_msg recommend "$TIP_CORE_UPDATE_COMMAND"
  else
    printf "$INFO_CORE_VERSION_LATEST\n" "$current_version"
  fi
}

# =====================================
# 🔍 core_get_current_version – Trả về phiên bản hiện tại từ version.txt
# =====================================
core_get_current_version() {
  local version_file="$BASE_DIR/version.txt"
  debug_log "version.txt URL: $version_file"
  if [[ -f "$version_file" ]]; then
    cat "$version_file" | tr -d '\n'
  else
    echo "0.0.0"
  fi
}

# =============================================
# 🔍 core_get_latest_version – Lấy version mới nhất từ GitHub theo channel
# =============================================
core_get_latest_version() {
  local channel version_url

  channel="$(core_get_channel)"

  if [[ "$channel" == "official" ]]; then
    version_url="https://raw.githubusercontent.com/thachpn165/wp-docker/refs/heads/main/src/version.txt"
  elif [[ "$channel" == "nightly" ]]; then
    version_url="https://raw.githubusercontent.com/thachpn165/wp-docker/refs/heads/dev/src/version.txt"
  else
    print_msg error "❌ Invalid CORE_CHANNEL: $channel"
    return 1
  fi

  curl -fsSL "$version_url" | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+(-[a-z]+)?(\+[0-9]+)?' | head -n1
}