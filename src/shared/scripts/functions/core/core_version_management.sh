#!/bin/bash

# ==============================
# Core Version Management Logic
# ==============================

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
