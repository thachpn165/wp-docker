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

# Hàm gọi script update.sh để cập nhật dự án
core_update_script() {
  echo "Đang cập nhật script từ GitHub..."
  bash src/update.sh  # Gọi script update.sh
  echo "Cập nhật hoàn tất!"
}
