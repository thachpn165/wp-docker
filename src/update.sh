#!/bin/bash

INSTALL_DIR="/opt/wp-docker"
TMP_DIR="/tmp/wp-docker-update"
REPO_URL="https://github.com/thachpn165/wp-docker"
ZIP_NAME="wp-docker.zip"
CORE_VERSION_FILE="version.txt"
CORE_TEMPLATE_VERSION_FILE="shared/templates/.template_version"
LOG_FILE="/tmp/update_wp_docker.log"

echo "📦 Đang cập nhật hệ thống WP Docker..." | tee -a "$LOG_FILE"

# ✅ Kiểm tra thư mục cài đặt
if [[ ! -d "$INSTALL_DIR" ]]; then
  echo "❌ Không tìm thấy $INSTALL_DIR. Bạn cần cài đặt bằng install.sh trước." | tee -a "$LOG_FILE"
  exit 1
fi

# ✅ Lưu version hiện tại
CURRENT_VERSION=$(cat "$INSTALL_DIR/version.txt" 2>/dev/null || echo "0.0.0")

# ✅ Tải bản release mới nhất
echo "📥 Tải bản release mới nhất từ GitHub..." | tee -a "$LOG_FILE"
curl -L "$REPO_URL/releases/latest/download/wp-docker.zip" -o "$ZIP_NAME"

# ✅ Giải nén vào thư mục tạm
echo "📁 Giải nén vào thư mục tạm: $TMP_DIR" | tee -a "$LOG_FILE"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
unzip -q "$ZIP_NAME" -d "$TMP_DIR"
rm "$ZIP_NAME"

# ✅ Lấy version mới
NEW_VERSION=$(cat "$TMP_DIR/$CORE_VERSION_FILE")
echo "🆕 Phiên bản mới: $NEW_VERSION" | tee -a "$LOG_FILE"
echo "📌 Phiên bản hiện tại: $CURRENT_VERSION" | tee -a "$LOG_FILE"

# ✅ Ghi đè các tệp hệ thống (không chạm vào data)
echo "♻️ Đang cập nhật các file hệ thống..." | tee -a "$LOG_FILE"

# Debug: Kiểm tra các thư mục được exclude
echo "🔴 Excluding directories: sites, logs, archives" | tee -a "$LOG_FILE"

# Chạy rsync với các thư mục loại trừ chính xác và lưu log chi tiết
rsync -a --delete \
  --exclude='/sites/' \
  --exclude='/logs/' \
  --exclude='/archives/' \
  --exclude='shared/config/config.sh' \
  "$TMP_DIR/" "$INSTALL_DIR/" | tee -a "$LOG_FILE"

# ✅ Ghi lại version mới
echo "$NEW_VERSION" > "$INSTALL_DIR/version.txt"

echo "✅ Đã cập nhật WP Docker lên phiên bản: $NEW_VERSION" | tee -a "$LOG_FILE"

# 🔎 Gợi ý bước tiếp theo: kiểm tra template của các site
echo ""
echo "🔍 Bước tiếp theo: Kiểm tra xem các website đang dùng cấu hình cũ không." | tee -a "$LOG_FILE"
echo "👉 Bạn có thể chạy: bash main.sh → 'Cập nhật cấu hình website đã cài'" | tee -a "$LOG_FILE"
echo ""

# 🧹 Xoá thư mục tạm
rm -rf "$TMP_DIR"

# ===========================
# 🔎 Kiểm tra version template của từng website
# ===========================

TEMPLATE_VERSION_NEW=$(cat "$INSTALL_DIR/shared/templates/.template_version" 2>/dev/null || echo "0.0.0")
echo ""
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
