#!/bin/bash

# =====================================
# 🛠 upgrade/v1.0.7-beta.sh
# Cập nhật template version cho các website trong thư mục sites/
# =====================================

INSTALL_DIR="/opt/wp-docker"
SITES_DIR="$INSTALL_DIR/sites"
TEMPLATE_VERSION="v1.0.0"

# Tạo mảng để lưu các website đã được cập nhật
updated_websites=()

echo "🔍 Đang quét các website trong thư mục $SITES_DIR..."

# Duyệt qua các thư mục con trong thư mục sites/
for site_path in "$SITES_DIR"/*/; do
  # Nếu là thư mục website
  if [ -d "$site_path" ]; then
    site_name=$(basename "$site_path")
    site_template_version_file="$site_path/.template_version"
    
    # Nếu website chưa có file .template_version
    if [ ! -f "$site_template_version_file" ]; then
      echo "🌍 Cập nhật website '$domain' với phiên bản template: $TEMPLATE_VERSION"
      echo "$TEMPLATE_VERSION" > "$site_template_version_file"  # Tạo file .template_version với version "v1.0.0"
      updated_websites+=("$domain")
    else
      echo "${WARNING} Website '$domain' đã có template version. Bỏ qua."
    fi
  fi
done

# Hiển thị kết quả
if [ ${#updated_websites[@]} -eq 0 ]; then
  echo "${CHECKMARK} Không có website nào cần cập nhật template version."
else
  echo "${CHECKMARK} Các website đã được cập nhật template version $TEMPLATE_VERSION:"
  for site in "${updated_websites[@]}"; do
    echo "  - $site"
  done
fi
