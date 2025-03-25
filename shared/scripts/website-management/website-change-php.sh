#!/bin/bash

# =====================================
# 🔀 website_change_php – Thay đổi phiên bản PHP cho website
# =====================================

#!/bin/bash

CONFIG_FILE="shared/config/config.sh"

# Xác định đường dẫn tuyệt đối của `config.sh`
while [ ! -f "$CONFIG_FILE" ]; do
    CONFIG_FILE="../$CONFIG_FILE"
    if [ "$(pwd)" = "/" ]; then
        echo "❌ Lỗi: Không tìm thấy config.sh!" >&2
        exit 1
    fi
done

source "$CONFIG_FILE"


select_website || exit 1

SITE_DIR="$SITES_DIR/$SITE_NAME"
ENV_FILE="$SITE_DIR/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo -e "${RED}❌ Không tìm thấy file .env trong website ${SITE_NAME}!${NC}"
  exit 1
fi

# Danh sách phiên bản PHP hỗ trợ
PHP_VERSIONS=("php74" "php80" "php81" "php82")
echo -e "${YELLOW}🔧 Chọn phiên bản PHP mới cho website ${SITE_NAME}:${NC}"
echo ""
echo -e "${YELLOW}⚠️ Ghi chú:${NC}"
echo -e "${RED}- Các phiên bản PHP 7.4 trở xuống có thể KHÔNG hoạt động trên hệ điều hành ARM như:${NC}"
echo -e "  ${CYAN}- Apple Silicon (Mac M1, M2), Raspberry Pi, hoặc máy chủ ARM64 khác${NC}"
echo -e "  ${WHITE}  → Nếu gặp lỗi \"platform mismatch\", bạn cần sửa docker-compose.yml và thêm:${NC}"
echo -e "     ${GREEN}platform: linux/amd64${NC}"

for i in "${!PHP_VERSIONS[@]}"; do
  echo -e "  ${GREEN}[$i]${NC} ${PHP_VERSIONS[$i]}"
done

read -p "🔹 Nhập số tương ứng: " php_index
selected_php="${PHP_VERSIONS[$php_index]}"

if [[ -z "$selected_php" ]]; then
  echo -e "${RED}❌ Lựa chọn không hợp lệ.${NC}"
  exit 1
fi

# Cập nhật phiên bản PHP trong file .env
sed -i.bak "s/^PHP_VERSION=.*/PHP_VERSION=$selected_php/" "$ENV_FILE"

echo -e "${GREEN}✅ Đã cập nhật phiên bản PHP thành: $selected_php${NC}"
echo -e "${YELLOW}🔄 Đang khởi động lại website để áp dụng thay đổi...${NC}"

# Dừng và xóa container PHP (không ảnh hưởng đến mariadb)
cd "$SITE_DIR"
docker compose stop php
docker rm -f "${SITE_NAME}-php" 2>/dev/null || true

# Khởi động lại PHP với phiên bản mới
docker compose up -d php

echo -e "${GREEN}✅ Website $SITE_NAME đã được chạy lại với PHP: $selected_php${NC}"
