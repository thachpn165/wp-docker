#!/bin/bash

core_version_dev_cache() {
  local cache_file="$BASE_DIR/latest_version_dev.txt"
  local url="${CORE_NIGHTLY_VERSION}"
  local expiration=43200 # 12h

  debug_log "[core_version_dev_cache] Checking cache file: $cache_file"

  if [[ -f "$cache_file" ]]; then
    local last_modified
    if [[ "$OSTYPE" == "darwin"* ]]; then
      last_modified=$(stat -f %m "$cache_file")
    else
      last_modified=$(stat -c %Y "$cache_file")
    fi
    local now=$(date +%s)
    local age=$((now - last_modified))

    debug_log "[core_version_dev_cache] Cache age: $age seconds"

    if [[ $age -gt $expiration ]]; then
      print_msg warning "$WARNING_CORE_DEV_CACHE_OUTDATED"
      run_cmd curl -s "$url" -o "$cache_file" true
    fi
  else
    print_msg info "$INFO_CORE_DEV_CACHE_MISSING"
    run_cmd curl -s "$url" -o "$cache_file" true
  fi

  cat "$cache_file"
}

core_display_dev_version() {
  local current_version
  local latest_version

  current_version=$(cat "$BASE_DIR/version.txt")
  latest_version=$(core_version_dev_cache)

  debug_log "[core_display_dev_version] Current version: $current_version"
  debug_log "[core_display_dev_version] Latest version (dev): $latest_version"

  core_compare_versions "$current_version" "$latest_version"
  result=$?

  if [[ $result -eq 2 ]]; then
    print_msg warning "$(printf "$WARNING_CORE_VERSION_NEW_AVAILABLE" "$current_version" "$latest_version")"
  else
    print_msg info "$(printf "$INFO_CORE_VERSION_LATEST" "$current_version")"
  fi
}