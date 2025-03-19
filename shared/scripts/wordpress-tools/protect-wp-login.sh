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
required_vars=("SITES_DIR" "NGINX_PROXY_DIR" "TEMPLATES_DIR")

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
read -p "Nhập số tương ứng với website cần quản lý bảo vệ wp-login.php: " site_index
site_name="${site_list[$site_index]}"

SITE_DIR="$SITES_DIR/$site_name"
NGINX_CONF_FILE="$NGINX_PROXY_DIR/conf.d/${site_name}.conf"
AUTH_FILE="$NGINX_PROXY_DIR/globals/.wp-login-auth-$site_name"
INCLUDE_FILE="$NGINX_PROXY_DIR/globals/wp-login-$site_name.conf"
TEMPLATE_FILE="$TEMPLATES_DIR/wp-login-template.conf"

echo -e "${YELLOW}🔧 Chọn hành động cho bảo vệ wp-login.php...${NC}"
echo -e "  ${GREEN}[1]${NC} Bật bảo vệ wp-login.php"
echo -e "  ${GREEN}[2]${NC} Tắt bảo vệ wp-login.php"
echo ""
read -p "Nhập lựa chọn của bạn: " action_choice

if [[ "$action_choice" == "1" ]]; then
    USERNAME=$(openssl rand -hex 4)
    PASSWORD=$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 16)

    # **Tạo tập tin xác thực mật khẩu trong thư mục `nginx-proxy/globals`**
    echo -e "${YELLOW}🔐 Đang tạo file xác thực mật khẩu...${NC}"
    echo "$USERNAME:$(openssl passwd -apr1 $PASSWORD)" > "$AUTH_FILE"

    # **Tạo tập tin cấu hình wp-login.php từ template**
    echo -e "${YELLOW}📄 Đang tạo tập tin cấu hình wp-login.php...${NC}"
    if [ -f "$TEMPLATE_FILE" ]; then
        sed "s|\$site_name|$site_name|g" "$TEMPLATE_FILE" > "$INCLUDE_FILE"
        echo -e "${GREEN}✅ Tập tin cấu hình đã được tạo: $INCLUDE_FILE${NC}"
    else
        echo -e "${RED}❌ Không tìm thấy template wp-login-template.conf!${NC}"
        exit 1
    fi

    # **Include file cấu hình vào NGINX ngay sau include cloudflare.conf**
    echo -e "${YELLOW}🔧 Đang cập nhật NGINX config để include wp-login.php...${NC}"
    if ! grep -q "include /etc/nginx/globals/wp-login-$site_name.conf;" "$NGINX_CONF_FILE"; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "/include \/etc\/nginx\/globals\/cloudflare.conf;/a\\
            include /etc/nginx/globals/wp-login-$site_name.conf;" "$NGINX_CONF_FILE"
        else
            sed -i "/include \/etc\/nginx\/globals\/cloudflare.conf;/a\\
            include /etc/nginx/globals/wp-login-$site_name.conf;" "$NGINX_CONF_FILE"
        fi
        echo -e "${GREEN}✅ Include wp-login.php đã được thêm vào cấu hình NGINX.${NC}"
        # **Kết thúc**
        # **Hiển thị thông tin đăng nhập sau khi bật bảo vệ**

echo ""
    echo -e "${GREEN}✅ wp-login.php đã được bảo vệ!${NC}"
        echo -e "${YELLOW}⚠️ Bạn sẽ cần nhập thông tin này khi truy cập vào admin hoặc đăng nhập vào WordPress, hãy lưu lại trước khi thoát ra${NC}"
    echo -e "🔑 ${CYAN}Thông tin đăng nhập:${NC}"
    echo -e "  ${GREEN}Username:${NC} $USERNAME"
    echo -e "  ${GREEN}Password:${NC} $PASSWORD"

echo ""
    fi

elif [[ "$action_choice" == "2" ]]; then
    echo -e "${YELLOW}🔧 Đang gỡ bỏ bảo vệ wp-login.php...${NC}"
    if [ -f "$INCLUDE_FILE" ]; then
        echo -e "${YELLOW}🗑️ Đang xóa tập tin cấu hình wp-login.php...${NC}"
        rm -f "$INCLUDE_FILE"
        echo -e "${GREEN}✅ Tập tin cấu hình wp-login.php đã được xóa.${NC}"
    fi

    # **Gỡ dòng include trong NGINX config**
    echo -e "${YELLOW}🔧 Đang cập nhật NGINX config để gỡ bỏ include...${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' -e "/include \/etc\/nginx\/globals\/wp-login-$site_name.conf;/d" "$NGINX_CONF_FILE"
    else
        sed -i -e "/include \/etc\/nginx\/globals\/wp-login-$site_name.conf;/d" "$NGINX_CONF_FILE"
    fi
    echo -e "${GREEN}✅ Dòng include đã được gỡ bỏ.${NC}"

    # **Xóa file xác thực nếu tồn tại**
    if [ -f "$AUTH_FILE" ]; then
        echo -e "${YELLOW}🗑️ Đang xóa file xác thực mật khẩu...${NC}"
        rm -f "$AUTH_FILE"
        echo -e "${GREEN}✅ File xác thực mật khẩu đã được xóa.${NC}"
    fi
fi

# **Reload NGINX để áp dụng thay đổi**
docker exec nginx-proxy nginx -s reload > /dev/null 2>&1
echo -e "${GREEN}✅ NGINX đã được reload thành công.${NC}"




echo ""
    # **Dừng lại cho đến khi người dùng nhấn Enter để thoát**
echo -e "${YELLOW}🔚 Nhấn Enter để thoát...${NC}"
read -r
