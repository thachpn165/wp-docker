#!/bin/bash

wordpress_protect_wp_login_logic() {

    site_name="$1"  # site_name sẽ được truyền từ file menu hoặc CLI

    SITE_DIR="$SITES_DIR/$site_name"
    NGINX_CONF_FILE="$NGINX_PROXY_DIR/conf.d/${site_name}.conf"
    AUTH_FILE="$NGINX_PROXY_DIR/globals/.wp-login-auth-$site_name"
    INCLUDE_FILE="$NGINX_PROXY_DIR/globals/wp-login-$site_name.conf"
    TEMPLATE_FILE="$TEMPLATES_DIR/wp-login-template.conf"

    # 📋 **Lựa chọn hành động bật/tắt bảo vệ wp-login.php**
    if [[ "$2" == "enable" ]]; then
        USERNAME=$(openssl rand -hex 4)
        PASSWORD=$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 16)

        # **Tạo tập tin xác thực mật khẩu trong thư mục `nginx-proxy/globals`**
        echo -e "${YELLOW}🔐 Đang tạo file xác thực mật khẩu...${NC}"
        echo "$USERNAME:$(openssl passwd -apr1 $PASSWORD)" > "$AUTH_FILE"

        # **Tạo tập tin cấu hình wp-login.php từ template**
        echo -e "${YELLOW}📄 Đang tạo tập tin cấu hình wp-login.php...${NC}"
        if [ -f "$TEMPLATE_FILE" ]; then
            sed "s|\$site_name|$site_name|g" "$TEMPLATE_FILE" > "$INCLUDE_FILE"
            echo -e "${GREEN}${CHECKMARK} Tập tin cấu hình đã được tạo: $INCLUDE_FILE${NC}"
        else
            echo -e "${RED}${CROSSMARK} Không tìm thấy template wp-login-template.conf!${NC}"
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
            echo -e "${GREEN}${CHECKMARK} Include wp-login.php đã được thêm vào cấu hình NGINX.${NC}"
            # **Hiển thị thông tin đăng nhập sau khi bật bảo vệ**
            echo -e "${GREEN}${CHECKMARK} wp-login.php đã được bảo vệ!${NC}"
            echo -e "${YELLOW}${WARNING} Bạn sẽ cần nhập thông tin này khi truy cập vào admin hoặc đăng nhập vào WordPress, hãy lưu lại trước khi thoát ra${NC}"
            echo -e "🔑 ${CYAN}Thông tin đăng nhập:${NC}"
            echo -e "  ${GREEN}Username:${NC} $USERNAME"
            echo -e "  ${GREEN}Password:${NC} $PASSWORD"
        fi

    elif [[ "$2" == "disable" ]]; then
        echo -e "${YELLOW}🔧 Đang gỡ bỏ bảo vệ wp-login.php...${NC}"
        if [ -f "$INCLUDE_FILE" ]; then
            echo -e "${YELLOW}🗑️ Đang xóa tập tin cấu hình wp-login.php...${NC}"
            rm -f "$INCLUDE_FILE"
            echo -e "${GREEN}${CHECKMARK} Tập tin cấu hình wp-login.php đã được xóa.${NC}"
        fi

        # **Gỡ dòng include trong NGINX config**
        echo -e "${YELLOW}🔧 Đang cập nhật NGINX config để gỡ bỏ include...${NC}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' -e "/include \/etc\/nginx\/globals\/wp-login-$site_name.conf;/d" "$NGINX_CONF_FILE"
        else
            sed -i -e "/include \/etc\/nginx\/globals\/wp-login-$site_name.conf;/d" "$NGINX_CONF_FILE"
        fi
        echo -e "${GREEN}${CHECKMARK} Dòng include đã được gỡ bỏ.${NC}"

        # **Xóa file xác thực nếu tồn tại**
        if [ -f "$AUTH_FILE" ]; then
            echo -e "${YELLOW}🗑️ Đang xóa file xác thực mật khẩu...${NC}"
            rm -f "$AUTH_FILE"
            echo -e "${GREEN}${CHECKMARK} File xác thực mật khẩu đã được xóa.${NC}"
        fi
    fi

    # **Reload NGINX để áp dụng thay đổi**
    nginx_reload
}
