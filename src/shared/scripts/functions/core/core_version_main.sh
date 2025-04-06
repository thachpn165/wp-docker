#!/bin/bash

core_version_main_cache() {
  local cache_file="$BASE_DIR/latest_version_main.txt"
  local url="${CORE_LATEST_VERSION}"
  local expiration=43200 # 12h

  if [[ -f "$cache_file" ]]; then
    local last_modified
    if [[ "$OSTYPE" == "darwin"* ]]; then
      last_modified=$(stat -f %m "$cache_file")
    else
      last_modified=$(stat -c %Y "$cache_file")
    fi
    local now=$(date +%s)
    local age=$((now - last_modified))

    if [[ $age -gt $expiration ]]; then
      #echo "${WARNING} Cache for main version is outdated. Fetching again..."
      print_msg "progress" "$WARNING_CORE_VERSION_FILE_OUTDATED"
      curl -s "$url" -o "$cache_file"
      exit_if_error "$?" "$ERROR_CORE_VERSION_FAILED_FETCH"
    fi
  else
    print_msg "progress" "$WARNING_CORE_VERSION_FILE_OUTDATED"
    curl -s "$url" -o "$cache_file"
    exit_if_error "$?" "$ERROR_CORE_VERSION_FAILED_FETCH"
  fi

  cat "$cache_file"
}

core_display_main_version() {
  local current_version=$(cat "$CORE_CURRENT_VERSION")
  local latest_version=$(core_version_main_cache)

  core_compare_versions "$current_version" "$latest_version"
  result=$?

  if [[ $result -eq 2 ]]; then
   # echo -e "📦 WP Docker Version: ${current_version} ${RED}(new version available: $latest_version)${NC}"
    print_msg "info" "$INFO_LABEL_CORE_VERSION : $current_version → ${RED}$latest_version${NC}"
  else
    print_msg "info" "$INFO_LABEL_CORE_VERSION : $current_version ${GREEN}($MSG_LATEST)${NC}"
  fi
}