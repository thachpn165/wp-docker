#!/bin/bash

# === 🧠 Automatically determine PROJECT_DIR (source root) ===
if [[ -z "$PROJECT_DIR" ]]; then
  SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
  while [[ "$SCRIPT_PATH" != "/" ]]; do
    if [[ -f "$SCRIPT_PATH/shared/config/config.sh" ]]; then
      PROJECT_DIR="$SCRIPT_PATH"
      break
    fi
    SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
  done
fi

# === ${CHECKMARK} Load config.sh from PROJECT_DIR ===
CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "${CROSSMARK} config.sh not found at: $CONFIG_FILE" >&2
  exit 1
fi
source "$CONFIG_FILE"

# Function to check installation directory
core_check_install_dir() {
  if [[ ! -d "$INSTALL_DIR" ]]; then
    echo "${CROSSMARK} $INSTALL_DIR not found. You need to install using install.sh first." | tee -a "$LOG_FILE"
    exit 1
  fi
}

# Function to download latest release from GitHub
core_download_latest_release() {
  echo "📥 Downloading latest release from GitHub..." | tee -a "$LOG_FILE"
  curl -L "$REPO_URL/releases/latest/download/wp-docker.zip" -o "$ZIP_NAME"
}

# Function to extract release to temporary directory
core_extract_release() {
  echo "📁 Extracting to temporary directory: $TMP_DIR" | tee -a "$LOG_FILE"
  rm -rf "$TMP_DIR"
  mkdir -p "$TMP_DIR"
  unzip -q "$ZIP_NAME" -d "$TMP_DIR"
  rm "$ZIP_NAME"
}

# Function to update system files from new release
core_update_system_files() {
  echo "♻️ Updating system files..." | tee -a "$LOG_FILE"
  rsync -a --delete \
    --exclude='/sites/' \
    --exclude='/logs/' \
    --exclude='/archives/' \
    "$TMP_DIR/" "$INSTALL_DIR/" | tee -a "$LOG_FILE"
}

# Function to update version.txt with new version
core_update_version_file() {
  NEW_VERSION=$(cat "$TMP_DIR/$CORE_VERSION_FILE")
  echo "$NEW_VERSION" > "$INSTALL_DIR/version.txt"
  echo "${CHECKMARK} WP Docker has been updated to version: $NEW_VERSION" | tee -a "$LOG_FILE"
}

# Function to clean up temporary files
core_cleanup() {
  rm -rf "$TMP_DIR"
}

# Function to check and list websites using old template
core_check_template_version() {
  TEMPLATE_VERSION_NEW=$(cat "$INSTALL_DIR/shared/templates/.template_version" 2>/dev/null || echo "0.0.0")
  echo "🔧 Current template version: $TEMPLATE_VERSION_NEW" | tee -a "$LOG_FILE"
  echo "🔍 Checking sites using old template..." | tee -a "$LOG_FILE"

  outdated_sites=()

  for site_path in "$INSTALL_DIR/sites/"*/; do
    [ -d "$site_path" ] || continue
    site_name=$(basename "$site_path")
    site_ver_file="$site_path/.template_version"

    site_template_version=$(cat "$site_ver_file" 2>/dev/null || echo "unknown")

    if [[ "$site_template_version" != "$TEMPLATE_VERSION_NEW" ]]; then
      outdated_sites+=("$site_name ($site_template_version)")
    fi
  done

  if [[ ${#outdated_sites[@]} -eq 0 ]]; then
    echo "${CHECKMARK} All sites are using the latest template." | tee -a "$LOG_FILE"
  else
    echo "${WARNING} The following sites are using OLD template:" | tee -a "$LOG_FILE"
    for s in "${outdated_sites[@]}"; do
      echo "  - $s → should update to $TEMPLATE_VERSION_NEW" | tee -a "$LOG_FILE"
    done
    echo ""
    echo "👉 Go to main menu (main.sh) → select 'Update installed website configuration'" | tee -a "$LOG_FILE"
  fi
}

# Function to run upgrade scripts if available in upgrade directory
core_run_upgrade_scripts() {
  UPGRADE_DIR="$INSTALL_DIR/upgrade/$NEW_VERSION"
  if [[ -d "$UPGRADE_DIR" ]]; then
    echo "🚀 Found upgrade directory for version $NEW_VERSION. Running scripts..." | tee -a "$LOG_FILE"

    # Run all scripts in upgrade/{version} directory
    for script in "$UPGRADE_DIR"/*.sh; do
      if [[ -f "$script" ]]; then
        echo "🎯 Running upgrade script: $script" | tee -a "$LOG_FILE"
        bash "$script" | tee -a "$LOG_FILE"
      fi
    done
  else
    echo "${CHECKMARK} No upgrade scripts found for version $NEW_VERSION." | tee -a "$LOG_FILE"
  fi
}

# Function to run the complete update process
core_update_system() {
  # Ask user to confirm update
  echo -e "${YELLOW}${WARNING} Are you sure you want to update WP Docker to the latest version? (y/n)${NC}"
  [[ "$TEST_MODE" != true ]] && read -p "Enter 'y' to continue, 'n' to cancel: " choice
  if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
    echo -e "${GREEN}${CHECKMARK} Update process cancelled.${NC}"
    exit 0
  fi

  # If user agrees, proceed with update steps
  core_check_install_dir
  core_download_latest_release
  core_extract_release
  core_update_system_files
  core_update_version_file
  core_check_template_version
  core_run_upgrade_scripts
  core_cleanup
}

