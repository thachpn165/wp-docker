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

# 🛠 **Kiểm tra biến quan trọng**
required_vars=("PROJECT_ROOT" "SITES_DIR" "NGINX_PROXY_CONTAINER")

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}❌ Lỗi: Biến '$var' chưa được định nghĩa trong config.sh${NC}"
        exit 1
    fi
done

# 📋 **Hiển thị danh sách website để chọn**
echo -e "${YELLOW}📋 Danh sách các website có thể restart:${NC}"
site_list=($(ls -1 "$SITES_DIR"))

if [ ${#site_list[@]} -eq 0 ]; then
    echo -e "${RED}❌ Không có website nào để restart.${NC}"
    exit 1
fi

for i in "${!site_list[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${site_list[$i]}"
done

echo ""
read -p "Nhập số tương ứng với website cần restart: " site_index
site_name="${site_list[$site_index]}"

SITE_DIR="$SITES_DIR/$site_name"

# **Kiểm tra xem website có tồn tại không**
if ! is_directory_exist "$SITE_DIR"; then
    echo -e "${RED}❌ Website '$site_name' không tồn tại!${NC}"
    exit 1
fi

echo -e "${BLUE}🔄 Đang restart website '$site_name'...${NC}"

# **Restart Docker Compose cho website**
cd "$SITE_DIR"
docker-compose down && docker-compose up -d
cd "$PROJECT_ROOT"

echo -e "${GREEN}✅ Website '$site_name' đã được restart thành công!${NC}"

# **Reload NGINX Proxy để cập nhật lại cấu hình**
restart_nginx_proxy

echo -e "${GREEN}✅ NGINX đã được reload.${NC}"

read -p "Nhấn Enter để quay lại menu..."