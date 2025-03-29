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
echo -e "${YELLOW}📋 Danh sách các website có thể reset mật khẩu Admin:${NC}"
site_list=($(ls -1 "$SITES_DIR"))

if [ ${#site_list[@]} -eq 0 ]; then
    echo -e "${RED}❌ Không có website nào để reset mật khẩu.${NC}"
    exit 1
fi

for i in "${!site_list[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${site_list[$i]}"
done

echo ""
[[ "$TEST_MODE" != true ]] && read -p "Nhập số tương ứng với website cần reset mật khẩu: " site_index
site_name="${site_list[$site_index]}"

SITE_DIR="$SITES_DIR/$site_name"
PHP_CONTAINER="$site_name-php"

# **Lấy danh sách người dùng**
echo -e "${YELLOW}📋 Danh sách tài khoản Admin:${NC}"
docker exec -u root "$PHP_CONTAINER" wp user list --role=administrator --fields=ID,user_login --format=table --allow-root --path=/var/www/html

echo ""
[[ "$TEST_MODE" != true ]] && read -p "Nhập ID của tài khoản cần reset mật khẩu: " user_id

# **Tạo mật khẩu ngẫu nhiên 18 ký tự không có ký tự đặc biệt**
new_password=$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 18)

echo -e "${YELLOW}🔄 Đang cập nhật mật khẩu...${NC}"
docker exec -u root "$PHP_CONTAINER" wp user update "$user_id" --user_pass="$new_password" --allow-root --path=/var/www/html

echo -e "${GREEN}✅ Mật khẩu mới của tài khoản ID $user_id: $new_password${NC}"

echo -e "${YELLOW}⚠️ Hãy lưu mật khẩu này ở nơi an toàn!${NC}"

[[ "$TEST_MODE" != true ]] && read -p "Nhấn Enter để quay lại menu..."
