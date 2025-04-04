#!/bin/bash

# ==============================
# Core Version Management Logic
# ==============================

# === Function: Cache the latest version with 12-hour expiration ===
core_version_cache() {
  CACHE_FILE="$BASE_DIR/latest_version.txt"
  CACHE_EXPIRATION_TIME=43200  # 12 hours in seconds

  if [[ -f "$CACHE_FILE" ]]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      FILE_MOD_TIME=$(stat -f %m "$CACHE_FILE")
    else
      FILE_MOD_TIME=$(stat -c %Y "$CACHE_FILE")
    fi

    CURRENT_TIME=$(date +%s)
    FILE_AGE=$((CURRENT_TIME - FILE_MOD_TIME))

    if [[ $FILE_AGE -gt $CACHE_EXPIRATION_TIME ]]; then
      echo "${WARNING} Cache is outdated. Fetching latest version..."
      LATEST_VERSION=$(curl -s "$CORE_LATEST_VERSION")
      echo "$LATEST_VERSION" > "$CACHE_FILE"
    else
      LATEST_VERSION=$(cat "$CACHE_FILE")
    fi
  else
    echo "${CROSSMARK} No version cache found. Fetching from GitHub..."
    LATEST_VERSION=$(curl -s "$CORE_LATEST_VERSION")
    echo "$LATEST_VERSION" > "$CACHE_FILE"
  fi

  echo "$LATEST_VERSION"
}

# === Function: Compare two versions ===
core_compare_versions() {
  local v1=$(echo "$1" | sed 's/^v//')
  local v2=$(echo "$2" | sed 's/^v//')

  if [[ "$v1" == "$v2" ]]; then return 0; fi

  sorted=$(printf "%s\n%s" "$v1" "$v2" | sort -V | head -n1)
  if [[ "$sorted" == "$v1" ]]; then
    return 2  # $1 < $2
  else
    return 1  # $1 > $2
  fi
}

# === Function: Return latest version (from cache or GitHub) ===
core_get_version() {
  VERSION=$(core_version_cache)
  echo "$VERSION"
}

# === Function: Display current version and update status ===
core_display_version() {
  CURRENT_VERSION=$(cat "$BASE_DIR/version.txt")
  LATEST_VERSION=$(core_version_cache)

  core_compare_versions "$CURRENT_VERSION" "$LATEST_VERSION"
  result=$?

  if [[ "$result" -eq 2 ]]; then
    echo -e "📦 WP Docker Version: ${CURRENT_VERSION} ${RED}(new version available: $LATEST_VERSION)${NC}"
  else
    echo -e "${BLUE}📦 WP Docker Version:${NC} ${CURRENT_VERSION} ${GREEN}(latest)${NC}"
  fi
}

# === Function: Check and notify about new version (used in main menu) ===
core_check_for_update() {
  CURRENT_VERSION=$(cat "$BASE_DIR/version.txt")
  LATEST_VERSION=$(core_version_cache)

  core_compare_versions "$CURRENT_VERSION" "$LATEST_VERSION"
  result=$?

  if [[ "$result" -eq 2 ]]; then
    echo "${WARNING} New version available! Current: $CURRENT_VERSION → Latest: $LATEST_VERSION"
    echo "👉 Run: ${CYAN}wpdocker core update${NC} to upgrade the system."
  else
    echo "You are using the latest version: $CURRENT_VERSION"
  fi
}