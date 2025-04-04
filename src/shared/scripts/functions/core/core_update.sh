#!/bin/bash

# === core_update.sh ===
# This file contains logic to perform the update of WP Docker system

core_update_system_logic() {
  echo -e "${YELLOW}🚀 Starting system update...${NC}"

  local download_url
  local zip_name="wp-docker.zip"
  local extract_dir="/tmp/wp-docker-update"

  # Determine update source based on version mode
  if [[ "$CORE_VERSION_MODE" == "nightly" ]]; then
    download_url="https://github.com/thachpn165/wp-docker/releases/download/dev/wp-docker-dev.zip"
    zip_name="wp-docker-dev.zip"
  else
    download_url="https://github.com/thachpn165/wp-docker/releases/latest/download/$zip_name"
  fi

  echo -e "📥 Downloading update from: $download_url"

  mkdir -p "$extract_dir"
  curl -L "$download_url" -o "$zip_name" || {
    echo -e "${RED}${CROSSMARK} Failed to download update archive.${NC}"
    return 1
  }

  echo -e "📦 Extracting update package..."
  unzip -q "$zip_name" -d "$extract_dir" || {
    echo -e "${RED}${CROSSMARK} Failed to extract update archive.${NC}"
    return 1
  }

  echo -e "🔁 Replacing project files..."
  rsync -a --exclude='.git' --exclude='logs/' --exclude='tmp/' "$extract_dir/" "$PROJECT_DIR/"

  echo -e "🧹 Cleaning up..."
  rm -rf "$extract_dir" "$zip_name"

  echo -e "${GREEN}${CHECKMARK} Update completed successfully!${NC}"
}