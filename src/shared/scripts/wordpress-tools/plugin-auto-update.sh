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
required_vars=("SITES_DIR")

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}❌ Lỗi: Biến '$var' chưa được định nghĩa trong config.sh${NC}"
        exit 1
    fi
done

# 📋 **Hiển thị danh sách website để chọn**
echo -e "${YELLOW}📋 Danh sách các website có thể bật/tắt tự cập nhật plugin:${NC}"
site_list=($(ls -1 "$SITES_DIR"))

if [ ${#site_list[@]} -eq 0 ]; then
    echo -e "${RED}❌ Không có website nào để thực hiện thao tác này.${NC}"
    exit 1
fi

for i in "${!site_list[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${site_list[$i]}"
done

echo ""
[[ "$TEST_MODE" != true ]] && read -p "Nhập số tương ứng với website cần bật/tắt tự cập nhật plugin: " site_index
site_name="${site_list[$site_index]}"

SITE_DIR="$SITES_DIR/$site_name"
PHP_CONTAINER="$site_name-php"

# **Lấy danh sách plugin hiện có**
echo -e "${YELLOW}📋 Danh sách plugin trên website '$site_name':${NC}"
docker exec -u root "$PHP_CONTAINER" wp plugin list --field=name --allow-root --path=/var/www/html

echo ""
[[ "$TEST_MODE" != true ]] && read -p "Bạn có muốn bật (y) hay tắt (n) tự động cập nhật plugin? (y/n): " enable_update

if [[ "$enable_update" == "y" ]]; then
    echo -e "${YELLOW}🔄 Đang bật tự động cập nhật cho toàn bộ plugin...${NC}"
    docker exec -u root "$PHP_CONTAINER" wp plugin auto-updates enable --all --allow-root --path=/var/www/html
    echo -e "${GREEN}✅ Tự động cập nhật đã được bật cho tất cả plugin trên '$site_name'.${NC}"
elif [[ "$enable_update" == "n" ]]; then
    echo -e "${YELLOW}🔄 Đang tắt tự động cập nhật cho toàn bộ plugin...${NC}"
    docker exec -u root "$PHP_CONTAINER" wp plugin auto-updates disable --all --allow-root --path=/var/www/html
    echo -e "${GREEN}✅ Tự động cập nhật đã được tắt cho tất cả plugin trên '$site_name'.${NC}"
else
    echo -e "${RED}❌ Lựa chọn không hợp lệ.${NC}"
    exit 1
fi

[[ "$TEST_MODE" != true ]] && read -p "Nhấn Enter để quay lại menu..."
