#!/bin/bash

# === 🧠 Tự động xác định PROJECT_DIR (gốc mã nguồn) ===
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

# === ✅ Load config.sh từ PROJECT_DIR ===
CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Không tìm thấy config.sh tại: $CONFIG_FILE" >&2
  exit 1
fi
source "$CONFIG_FILE"

# Hàm kiểm tra thư mục cài đặt
core_check_install_dir() {
  if [[ ! -d "$INSTALL_DIR" ]]; then
    echo "❌ Không tìm thấy $INSTALL_DIR. Bạn cần cài đặt bằng install.sh trước." | tee -a "$LOG_FILE"
    exit 1
  fi
}

# Hàm tải bản release mới nhất từ GitHub
core_download_latest_release() {
  echo "📥 Tải bản release mới nhất từ GitHub..." | tee -a "$LOG_FILE"
  curl -L "$REPO_URL/releases/latest/download/wp-docker.zip" -o "$ZIP_NAME"
}

# Hàm giải nén bản release vào thư mục tạm
core_extract_release() {
  echo "📁 Giải nén vào thư mục tạm: $TMP_DIR" | tee -a "$LOG_FILE"
  rm -rf "$TMP_DIR"
  mkdir -p "$TMP_DIR"
  unzip -q "$ZIP_NAME" -d "$TMP_DIR"
  rm "$ZIP_NAME"
}

# Hàm cập nhật các file hệ thống từ bản release mới
core_update_system_files() {
  echo "♻️ Đang cập nhật các file hệ thống..." | tee -a "$LOG_FILE"
  rsync -a --delete \
    --exclude='/sites/' \
    --exclude='/logs/' \
    --exclude='/archives/' \
    "$TMP_DIR/" "$INSTALL_DIR/" | tee -a "$LOG_FILE"
}

# Hàm cập nhật file version.txt với phiên bản mới
core_update_version_file() {
  NEW_VERSION=$(cat "$TMP_DIR/$CORE_VERSION_FILE")
  echo "$NEW_VERSION" > "$INSTALL_DIR/version.txt"
  echo "✅ Đã cập nhật WP Docker lên phiên bản: $NEW_VERSION" | tee -a "$LOG_FILE"
}

# Hàm dọn dẹp các file tạm
core_cleanup() {
  rm -rf "$TMP_DIR"
}

# Hàm kiểm tra và liệt kê các website sử dụng template cũ
core_check_template_version() {
  TEMPLATE_VERSION_NEW=$(cat "$INSTALL_DIR/shared/templates/.template_version" 2>/dev/null || echo "0.0.0")
  echo "🔧 Template version hiện tại: $TEMPLATE_VERSION_NEW" | tee -a "$LOG_FILE"
  echo "🔍 Đang kiểm tra các site dùng template cũ..." | tee -a "$LOG_FILE"

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
    echo "✅ Tất cả site đang dùng template mới nhất." | tee -a "$LOG_FILE"
  else
    echo "⚠️ Các site sau đang dùng template CŨ:" | tee -a "$LOG_FILE"
    for s in "${outdated_sites[@]}"; do
      echo "  - $s → nên cập nhật lên $TEMPLATE_VERSION_NEW" | tee -a "$LOG_FILE"
    done
    echo ""
    echo "👉 Vào menu chính (main.sh) → chọn 'Cập nhật cấu hình website đã cài'" | tee -a "$LOG_FILE"
  fi
}

# Hàm chạy các script nâng cấp nếu có trong thư mục upgrade
core_run_upgrade_scripts() {
  UPGRADE_DIR="$INSTALL_DIR/upgrade/$NEW_VERSION"
  if [[ -d "$UPGRADE_DIR" ]]; then
    echo "🚀 Tìm thấy thư mục upgrade cho phiên bản $NEW_VERSION. Đang chạy các script trong đó..." | tee -a "$LOG_FILE"

    # Chạy tất cả các script trong thư mục upgrade/{version}
    for script in "$UPGRADE_DIR"/*.sh; do
      if [[ -f "$script" ]]; then
        echo "🎯 Đang chạy script nâng cấp: $script" | tee -a "$LOG_FILE"
        bash "$script" | tee -a "$LOG_FILE"
      fi
    done
  else
    echo "✅ Không có script nâng cấp nào cho phiên bản $NEW_VERSION." | tee -a "$LOG_FILE"
  fi
}

# Chạy toàn bộ quy trình cập nhật
core_update_system() {
  core_check_install_dir
  core_download_latest_release
  core_extract_release
  core_update_system_files
  core_update_version_file
  core_check_template_version
  core_run_upgrade_scripts
  core_cleanup
}
