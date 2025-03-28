#!/bin/bash

# Function to check and cache the latest version with 6-hour expiration
core_version_cache() {
  CACHE_FILE="$BASE_DIR/latest_version.txt"
  CACHE_EXPIRATION_TIME=43200  # 12 hours in seconds

  # Check if cache file exists
  if [[ -f "$CACHE_FILE" ]]; then
    # Check operating system and get cache file modification time accordingly
    if [[ "$OSTYPE" == "darwin"* ]]; then
      # Use stat on macOS
      FILE_MOD_TIME=$(stat -f %m "$CACHE_FILE")
    else
      # Use stat on Linux
      FILE_MOD_TIME=$(stat -c %Y "$CACHE_FILE")
    fi
    
    CURRENT_TIME=$(date +%s)
    FILE_AGE=$((CURRENT_TIME - FILE_MOD_TIME))

    # If cache has expired (more than 12 hours), fetch new version from GitHub
    if [[ $FILE_AGE -gt $CACHE_EXPIRATION_TIME ]]; then
      echo "⚠️ Cache version is outdated. Fetching new version..."
      # Use CORE_LATEST_VERSION variable instead of hard-coding
      LATEST_VERSION=$(curl -s "$CORE_LATEST_VERSION")
      echo "$LATEST_VERSION" > "$CACHE_FILE"  # Save to cache
    else
      # If cache is still valid, just read from cache
      LATEST_VERSION=$(cat "$CACHE_FILE")
    fi
  else
    # If no cache file exists, fetch new version from GitHub
    echo "❌ No cache found. Fetching version from GitHub..."
    # Use CORE_LATEST_VERSION variable instead of hard-coding
    LATEST_VERSION=$(curl -s "$CORE_LATEST_VERSION")
    echo "$LATEST_VERSION" > "$CACHE_FILE"  # Save to cache
  fi

  echo "$LATEST_VERSION"
}

# Function to get and display project version
core_get_version() {
    VERSION=$(core_version_cache)
    echo "$VERSION"
}

# Function to check and compare current version with new version from cache or GitHub
core_check_version_update() {
  local current_version=$(cat version.txt)  # Get current version from version.txt
  local latest_version=$(core_version_cache)  # Call function to check latest version from cache
  
  if [[ "$current_version" != "$latest_version" ]]; then
    echo "New version available ($latest_version). Do you want to update? [y/n]"
    read -p "Enter choice: " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
      core_update_script  # Call update.sh script
    fi
  else
    echo "You are using the latest version: $current_version"
  fi
}

# Function to display WP Docker version from cache or GitHub
core_display_version() {
  # Get current version
  CURRENT_VERSION=$(cat "$BASE_DIR/version.txt")
  
  # Get latest version from cache or GitHub
  LATEST_VERSION=$(core_version_cache)

  # Display a single line
  if [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]]; then
    echo -e "${BLUE}📦 WP Docker Version:${NC} ${CURRENT_VERSION} ${GREEN}(latest)${NC}"
  else
    echo -e "📦 WP Docker Version: ${CURRENT_VERSION} ${RED}(new version available)${NC}"
  fi
}

# Function to check current version and compare with new version from cache or GitHub
core_check_for_update() {
  # Get current version
  CURRENT_VERSION=$(cat "$BASE_DIR/version.txt")
  
  # Get latest version from cache or GitHub
  LATEST_VERSION=$(core_version_cache)

  # If no cache or cache version is latest, just display message
  if [[ "$LATEST_VERSION" == "❌ No cache found. Fetching version from GitHub..." ]]; then
    echo "⚠️ No cache found, fetching new version from GitHub..."
    echo "👉 You can run the update feature to upgrade the system."
    return
  fi

  # Compare versions
  if [[ "$CURRENT_VERSION" != "$LATEST_VERSION" ]]; then
    echo "⚠️ New version available! Current version is $CURRENT_VERSION and latest version is $LATEST_VERSION."
    echo "👉 You can run the update feature to upgrade the system."
  else
    echo "✅ You are using the latest version: $CURRENT_VERSION"
  fi
}
