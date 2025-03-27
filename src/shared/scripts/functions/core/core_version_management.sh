#!/bin/bash

# Hàm lấy và hiển thị phiên bản của dự án
core_get_version() {
  local version=$(curl -s https://raw.githubusercontent.com/thachpn165/wp-docker/main/src/version.txt)
  echo "$version"
}

# Hàm kiểm tra và so sánh phiên bản hiện tại với phiên bản mới
core_check_version_update() {
  local current_version=$(cat version.txt)  # Lấy phiên bản hiện tại từ file version.txt
  local latest_version=$(curl -s https://raw.githubusercontent.com/thachpn165/wp-docker/main/src/version.txt)

  if [[ "$current_version" != "$latest_version" ]]; then
    echo "Có phiên bản mới ($latest_version). Bạn có muốn cập nhật không? [y/n]"
    read -p "Nhập lựa chọn: " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
      core_update_script  # Gọi script update.sh
    fi
  else
    echo "Bạn đang sử dụng phiên bản mới nhất: $current_version"
  fi
}

# === Hàm hiển thị phiên bản WP Docker: hiển thị phiên bản hiện tại và trạng thái (latest) ===
core_display_version() {
  # Lấy phiên bản hiện tại
  CURRENT_VERSION=$(cat "$INSTALL_DIR/version.txt")
  
  # Lấy phiên bản mới nhất từ GitHub
  LATEST_VERSION=$(curl -s https://raw.githubusercontent.com/thachpn165/wp-docker/main/src/version.txt)

  # Hiển thị một dòng duy nhất
  if [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]]; then
    echo -e "${BLUE}📦 Phiên bản WP Docker:${NC} ${CURRENT_VERSION} ${GREEN}(latest)${NC}"
  else
    echo -e "📦 Phiên bản WP Docker: ${CURRENT_VERSION} ${RED}(new version available)${NC}"
  fi
}


# === Hàm kiểm tra phiên bản hiện tại và so sánh với phiên bản mới ===
core_check_for_update() {
  # Lấy phiên bản hiện tại
  CURRENT_VERSION=$(cat "$INSTALL_DIR/version.txt")
  
  # Lấy phiên bản mới nhất từ GitHub
  LATEST_VERSION=$(curl -s https://raw.githubusercontent.com/thachpn165/wp-docker/main/src/version.txt)
  
  # So sánh các phiên bản
  if [[ "$CURRENT_VERSION" != "$LATEST_VERSION" ]]; then
    echo "⚠️ Có phiên bản mới! Phiên bản hiện tại là $CURRENT_VERSION và phiên bản mới nhất là $LATEST_VERSION."
    echo "👉 Bạn có thể chạy tính năng cập nhật để nâng cấp hệ thống."
  else
    echo "✅ Bạn đang sử dụng phiên bản mới nhất: $CURRENT_VERSION"
  fi
}
