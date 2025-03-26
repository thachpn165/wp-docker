# =====================================
# 🔀 website_change_php – Thay đổi phiên bản PHP cho website (dạng hàm)
# =====================================

php_change_version() {
  source "$CONFIG_FILE"

  select_website || return 1

  SITE_DIR="$SITES_DIR/$SITE_NAME"
  ENV_FILE="$SITE_DIR/.env"

  if [[ ! -f "$ENV_FILE" ]]; then
    echo -e "${RED}❌ Không tìm thấy file .env trong website ${SITE_NAME}!${NC}"
    return 1
  fi

  # Gọi hàm chọn phiên bản PHP dùng chung từ php_versions.sh
    php_choose_version || return 1
    selected_php="$REPLY"

  # Cập nhật phiên bản PHP trong file .env
  sed -i.bak "s/^PHP_VERSION=.*/PHP_VERSION=$selected_php/" "$ENV_FILE"

  echo -e "${GREEN}✅ Đã cập nhật phiên bản PHP thành: $selected_php${NC}"
  echo -e "${YELLOW}🔄 Đang khởi động lại website để áp dụng thay đổi...${NC}"

  # Dừng và xóa container PHP (không ảnh hưởng đến mariadb)
  cd "$SITE_DIR"
  docker compose stop php
  docker rm -f "${SITE_NAME}-php" 2>/dev/null || true

  # Khởi động lại PHP với phiên bản mới
  docker compose  up -d php

  echo -e "${GREEN}✅ Website $SITE_NAME đã được chạy lại với PHP: $selected_php${NC}"
}