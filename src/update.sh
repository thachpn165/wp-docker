# =====================================
# 🔄 update.sh – Cập nhật từ GitHub
# =====================================

#!/bin/bash

INSTALL_DIR="/opt/wp-docker"
TMP_DIR="/tmp/wp-docker-update"
REPO_URL="https://github.com/thachpn165/wp-docker"
ZIP_NAME="wp-docker.zip"
CORE_VERSION_FILE="version.txt"
CORE_TEMPLATE_VERSION_FILE="shared/templates/.template_version"

echo "📦 Đang cập nhật hệ thống WP Docker..."

# ✅ Kiểm tra thư mục cài đặt
if [[ ! -d "$INSTALL_DIR" ]]; then
  echo "❌ Không tìm thấy $INSTALL_DIR. Bạn cần cài đặt bằng install.sh trước."
  exit 1
fi

# ✅ Lưu version hiện tại
CURRENT_VERSION=$(cat "$INSTALL_DIR/version.txt" 2>/dev/null || echo "0.0.0")

# ✅ Tải bản release mới nhất
echo "📥 Tải bản release mới nhất từ GitHub..."
curl -L "$REPO_URL/releases/latest/download/wp-docker.zip" -o "$ZIP_NAME"

# ✅ Giải nén vào thư mục tạm
echo "📁 Giải nén vào thư mục tạm: $TMP_DIR"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
unzip -q "$ZIP_NAME" -d "$TMP_DIR"
rm "$ZIP_NAME"

# ✅ Lấy version mới
NEW_VERSION=$(cat "$TMP_DIR/$CORE_VERSION_FILE")
echo "🆕 Phiên bản mới: $NEW_VERSION"
echo "📌 Phiên bản hiện tại: $CURRENT_VERSION"

# ✅ Ghi đè các tệp hệ thống (không chạm vào data)
echo "♻️ Đang cập nhật các file hệ thống..."
rsync -a --delete \
  --exclude='sites' \
  --exclude='logs' \
  --exclude='archives' \
  --exclude='shared/config/config.sh' \
  "$TMP_DIR/" "$INSTALL_DIR/"

# ✅ Ghi lại version mới
echo "$NEW_VERSION" > "$INSTALL_DIR/version.txt"

echo "✅ Đã cập nhật WP Docker lên phiên bản: $NEW_VERSION"

# 🔎 Gợi ý bước tiếp theo: kiểm tra template của các site
echo ""
echo "🔍 Bước tiếp theo: Kiểm tra xem các website đang dùng cấu hình cũ không."
echo "👉 Bạn có thể chạy: bash main.sh → 'Cập nhật cấu hình website đã cài'"
echo ""

# 🧹 Xoá thư mục tạm
rm -rf "$TMP_DIR"

# ===========================
# 🔎 Kiểm tra version template của từng website
# ===========================

TEMPLATE_VERSION_NEW=$(cat "$INSTALL_DIR/shared/templates/.template_version" 2>/dev/null || echo "0.0.0")
echo ""
echo "🔧 Template version hiện tại: $TEMPLATE_VERSION_NEW"
echo "🔍 Đang kiểm tra các site dùng template cũ..."

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
  echo "✅ Tất cả site đang dùng template mới nhất."
else
  echo "⚠️ Các site sau đang dùng template CŨ:"
  for s in "${outdated_sites[@]}"; do
    echo "  - $s → nên cập nhật lên $TEMPLATE_VERSION_NEW"
  done
  echo ""
  echo "👉 Vào menu chính (main.sh) → chọn 'Cập nhật cấu hình website đã cài'"
fi
