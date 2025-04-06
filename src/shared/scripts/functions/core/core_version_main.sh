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
      echo "${WARNING} Cache for main version is outdated. Fetching again..."
      curl -s "$url" -o "$cache_file"
    fi
  else
    echo "${INFO} No cache for main version. Fetching..."
    curl -s "$url" -o "$cache_file"
  fi

  cat "$cache_file"
}

core_display_main_version() {
  local current_version=$(cat "$BASE_DIR/version.txt")
  local latest_version=$(core_version_main_cache)

  core_compare_versions "$current_version" "$latest_version"
  result=$?

  if [[ $result -eq 2 ]]; then
    echo -e "📦 WP Docker Version: ${current_version} ${RED}(new version available: $latest_version)${NC}"
  else
    echo -e "${BLUE}📦 WP Docker Version:${NC} ${current_version} ${GREEN}(latest)${NC}"
  fi
}