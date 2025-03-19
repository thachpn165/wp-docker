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

# 📋 **Hiển thị danh sách website để chọn**
echo -e "${YELLOW}📋 Danh sách các website có sẵn:${NC}"
site_list=($(ls -1 "$SITES_DIR"))

if [ ${#site_list[@]} -eq 0 ]; then
    echo -e "${RED}❌ Không có website nào để xem thông tin.${NC}"
    exit 1
fi

for i in "${!site_list[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${site_list[$i]}"
done

echo ""
read -p "Nhập số tương ứng với website cần xem thông tin: " site_index
site_name="${site_list[$site_index]}"

SITE_DIR="$SITES_DIR/$site_name"
ENV_FILE="$SITE_DIR/.env"

# **Lấy thông tin từ .env**
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    echo -e "${RED}❌ Không tìm thấy file .env cho site '$site_name'!${NC}"
    exit 1
fi

# **Xác định loại cache đang sử dụng**
CACHE_TYPE="no-cache"
if grep -q "CACHE_TYPE=" "$ENV_FILE"; then
    CACHE_TYPE=$(grep "CACHE_TYPE=" "$ENV_FILE" | cut -d '=' -f2)
fi

# **Lấy phiên bản PHP từ docker-compose.yml**
PHP_VERSION=$(grep -o 'php:[0-9]\+\.[0-9]\+' "$SITE_DIR/docker-compose.yml" | cut -d ':' -f2)

# **Hiển thị thông tin**
echo -e "${CYAN}=========================================${NC}"
echo -e "${GREEN}📜 Thông Tin Website:${NC}"
echo -e "${CYAN}=========================================${NC}"
echo -e "🔹 ${BOLD}Tên website:${NC} $site_name"
echo -e "🔹 ${BOLD}Tên miền:${NC} $DOMAIN"
echo -e "🔹 ${BOLD}Phiên bản PHP:${NC} $PHP_VERSION"
echo -e "🔹 ${BOLD}MySQL Database:${NC} $MYSQL_DATABASE"
echo -e "🔹 ${BOLD}MySQL User:${NC} $MYSQL_USER"
echo -e "🔹 ${BOLD}MySQL Password:${NC} $MYSQL_PASSWORD"
echo -e "🔹 ${BOLD}MySQL Root Password:${NC} $MYSQL_ROOT_PASSWORD"
echo -e "🔹 ${BOLD}Loại cache:${NC} $CACHE_TYPE"
echo -e "${CYAN}=========================================${NC}"

echo ""
echo -e "${YELLOW}🔚 Nhấn Enter để quay lại menu...${NC}"
read -r