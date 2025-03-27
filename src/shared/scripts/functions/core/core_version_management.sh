#!/bin/bash

# Hàm kiểm tra và lưu phiên bản mới nhất vào cache với thời gian hết hạn 6 giờ
core_version_cache() {
  CACHE_FILE="$BASE_DIR/latest_version.txt"
  CACHE_EXPIRATION_TIME=43200  # 12 hours in seconds

  # Kiểm tra xem file cache có tồn tại không
  if [[ -f "$CACHE_FILE" ]]; then
    # Kiểm tra hệ điều hành và lấy thời gian sửa đổi của file cache tương ứng
    if [[ "$OSTYPE" == "darwin"* ]]; then
      # Dùng stat trên macOS
      FILE_MOD_TIME=$(stat -f %m "$CACHE_FILE")
    else
      # Dùng stat trên Linux
      FILE_MOD_TIME=$(stat -c %Y "$CACHE_FILE")
    fi
    
    CURRENT_TIME=$(date +%s)
    FILE_AGE=$((CURRENT_TIME - FILE_MOD_TIME))

    # Nếu cache đã hết hạn (lớn hơn 12 giờ), tải lại phiên bản mới từ GitHub
    if [[ $FILE_AGE -gt $CACHE_EXPIRATION_TIME ]]; then
      echo "⚠️ Cache version is outdated. Fetching new version..."
      # Sử dụng biến CORE_LATEST_VERSION thay vì hard-code
      LATEST_VERSION=$(curl -s "$CORE_LATEST_VERSION")
      echo "$LATEST_VERSION" > "$CACHE_FILE"  # Lưu vào cache
    else
      # Nếu cache còn hiệu lực, chỉ đọc từ cache
      LATEST_VERSION=$(cat "$CACHE_FILE")
    fi
  else
    # Nếu không có file cache, tải phiên bản mới từ GitHub
    echo "❌ No cache found. Fetching version from GitHub..."
    # Sử dụng biến CORE_LATEST_VERSION thay vì hard-code
    LATEST_VERSION=$(curl -s "$CORE_LATEST_VERSION")
    echo "$LATEST_VERSION" > "$CACHE_FILE"  # Lưu vào cache
  fi

  echo "$LATEST_VERSION"
}



# Hàm lấy và hiển thị phiên bản của dự án
core_get_version() {
    VERSION=$(core_version_cache)
    echo "$VERSION"
}

# Hàm kiểm tra và so sánh phiên bản hiện tại với phiên bản mới từ cache hoặc GitHub
core_check_version_update() {
  local current_version=$(cat version.txt)  # Lấy phiên bản hiện tại từ file version.txt
  local latest_version=$(core_version_cache)  # Gọi hàm kiểm tra phiên bản mới nhất từ cache
  
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


# Hàm hiển thị phiên bản WP Docker từ cache hoặc GitHub
core_display_version() {
  # Lấy phiên bản hiện tại
  CURRENT_VERSION=$(cat "$BASE_DIR/version.txt")
  
  # Lấy phiên bản mới nhất từ cache hoặc GitHub
  LATEST_VERSION=$(core_version_cache)

  # Hiển thị một dòng duy nhất
  if [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]]; then
    echo -e "${BLUE}📦 Phiên bản WP Docker:${NC} ${CURRENT_VERSION} ${GREEN}(latest)${NC}"
  else
    echo -e "📦 Phiên bản WP Docker: ${CURRENT_VERSION} ${RED}(new version available)${NC}"
  fi
}



# Hàm kiểm tra phiên bản hiện tại và so sánh với phiên bản mới từ cache hoặc GitHub
core_check_for_update() {
  # Lấy phiên bản hiện tại
  CURRENT_VERSION=$(cat "$BASE_DIR/version.txt")
  
  # Lấy phiên bản mới nhất từ cache hoặc GitHub
  LATEST_VERSION=$(core_version_cache)

  # So sánh các phiên bản
  if [[ "$CURRENT_VERSION" != "$LATEST_VERSION" ]]; then
    echo "⚠️ Có phiên bản mới! Phiên bản hiện tại là $CURRENT_VERSION và phiên bản mới nhất là $LATEST_VERSION."
    echo "👉 Bạn có thể chạy tính năng cập nhật để nâng cấp hệ thống."
  else
    echo "✅ Bạn đang sử dụng phiên bản mới nhất: $CURRENT_VERSION"
  fi
}

