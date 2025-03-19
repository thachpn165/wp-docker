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
required_vars=("SITES_DIR" "NGINX_PROXY_DIR")

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}❌ Lỗi: Biến '$var' chưa được định nghĩa trong config.sh${NC}"
        exit 1
    fi
done

# 📋 **Hiển thị danh sách website để chọn**
echo -e "${YELLOW}📋 Danh sách các website có thể bảo vệ wp-login.php:${NC}"
site_list=($(ls -1 "$SITES_DIR"))

if [ ${#site_list[@]} -eq 0 ]; then
    echo -e "${RED}❌ Không có website nào để bảo vệ.${NC}"
    exit 1
fi

for i in "${!site_list[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${site_list[$i]}"
done

echo ""
read -p "Nhập số tương ứng với website cần bảo vệ: " site_index
site_name="${site_list[$site_index]}"

SITE_DIR="$SITES_DIR/$site_name"
NGINX_CONF_FILE="$NGINX_PROXY_DIR/conf.d/${site_name}.conf"
AUTH_FILE="$NGINX_PROXY_DIR/globals/wp-login-auth-$site_name"

USERNAME=$(openssl rand -hex 4)
PASSWORD=$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 16)

# **Tạo tập tin xác thực mật khẩu trong thư mục `nginx-proxy/globals`**
echo -e "${YELLOW}🔐 Đang tạo file xác thực mật khẩu...${NC}"
echo "$USERNAME:$(openssl passwd -apr1 $PASSWORD)" > "$AUTH_FILE"

# **Cập nhật cấu hình NGINX để bảo vệ wp-login.php**
echo -e "${YELLOW}🔧 Đang cập nhật cấu hình NGINX...${NC}"
if grep -q "location ~* /wp-login.php" "$NGINX_CONF_FILE"; then
    echo -e "${RED}⚠️ Cấu hình bảo vệ đã tồn tại trong NGINX!${NC}"
else
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "/include \/etc\/nginx\/globals\/cloudflare.conf;/a\\
        location ~* /wp-login.php {\\
            auth_basic \"Restricted Access\";\\
            auth_basic_user_file /etc/nginx/globals/wp-login-auth-$site_name;\\
            include /etc/nginx/globals/php.conf;\\
        }" "$NGINX_CONF_FILE"
    else
        sed -i "/include \/etc\/nginx\/globals\/cloudflare.conf;/a\\
        location ~* /wp-login.php {\\
            auth_basic \"Restricted Access\";\\
            auth_basic_user_file /etc/nginx/globals/wp-login-auth-$site_name;\\
            include /etc/nginx/globals/php.conf;\\
        }" "$NGINX_CONF_FILE"
    fi
    echo -e "${GREEN}✅ Cấu hình NGINX đã được cập nhật.${NC}"
fi


# **Reload NGINX để áp dụng thay đổi**
echo -e "${YELLOW}🔄 Đang reload NGINX...${NC}"
docker exec nginx-proxy nginx -s reload

echo -e "${GREEN}✅ wp-login.php đã được bảo vệ!${NC}"
echo -e "🔑 ${CYAN}Thông tin đăng nhập:${NC}"
echo -e "  ${GREEN}Username:${NC} $USERNAME"
echo -e "  ${GREEN}Password:${NC} $PASSWORD"

read -p "Nhấn Enter để quay lại menu..."
