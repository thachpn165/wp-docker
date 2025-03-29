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

# 📢 **Thông báo về tính năng**
echo -e "${YELLOW}⚠️ Tính năng này sẽ thiết lập lại quyền Administrator trên website về mặc định.${NC}"
echo -e "${YELLOW}⚠️ Được dùng trong trường hợp website bị lỗi tài khoản Admin bị thiếu/mất quyền.${NC}"
echo ""

# 📋 **Hiển thị danh sách website để chọn**
echo -e "${YELLOW}📋 Danh sách các website có thể sửa quyền thành viên:${NC}"
site_list=($(ls -1 "$SITES_DIR"))

if [ ${#site_list[@]} -eq 0 ]; then
    echo -e "${RED}❌ Không có website nào để sửa quyền thành viên.${NC}"
    exit 1
fi

for i in "${!site_list[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${site_list[$i]}"
done

echo ""
[[ "$TEST_MODE" != true ]] && read -p "Nhập số tương ứng với website cần sửa quyền thành viên: " site_index
site_name="${site_list[$site_index]}"

SITE_DIR="$SITES_DIR/$site_name"
PHP_CONTAINER="$site_name-php"

# **Chạy lệnh WP CLI để reset lại quyền**
echo -e "${YELLOW}🔄 Đang thiết lập lại quyền Administrator về mặc định...${NC}"
docker exec -u root "$PHP_CONTAINER" wp role reset --all --allow-root --path=/var/www/html

echo -e "${GREEN}✅ Quyền Administrator trên website '$site_name' đã được thiết lập lại thành công.${NC}"

[[ "$TEST_MODE" != true ]] && read -p "Nhấn Enter để quay lại menu..."
