#!/bin/bash

# =====================================
# 🐳 Tạo file cấu hình NGINX từ biến môi trường có sẵn
# =====================================

CONFIG_FILE="shared/config/config.sh"
while [ ! -f "$CONFIG_FILE" ]; do
    CONFIG_FILE="../$CONFIG_FILE"
    if [ "$(pwd)" = "/" ]; then
        echo "❌ Không tìm thấy config.sh!" >&2
        exit 1
    fi
done
source "$CONFIG_FILE"

# ✅ Kiểm tra biến đầu vào có tồn tại không
if [[ -z "$site_name" || -z "$domain" ]]; then
    echo -e "${RED}❌ Thiếu biến môi trường site_name hoặc domain. Hãy export trước khi gọi script.${NC}"
    exit 1
fi

# Kiểm tra sự tồn tại của thư mục đích (NGINX conf)
NGINX_CONF_DIR="$NGINX_PROXY_DIR/conf.d"
if [ ! -d "$NGINX_CONF_DIR" ]; then
    echo -e "${RED}❌ Thư mục cấu hình NGINX không tồn tại: $NGINX_CONF_DIR${NC}"
    exit 1
fi

# Tạo file cấu hình nginx từ template
NGINX_TEMPLATE="$TEMPLATES_DIR/nginx-proxy.conf.template"
NGINX_CONF="$NGINX_CONF_DIR/$site_name.conf"

# Nếu file cấu hình NGINX đã tồn tại, xóa đi trước khi tạo lại
if is_file_exist "$NGINX_CONF"; then
    echo -e "${YELLOW}🗑️ Xoá cấu hình NGINX cũ: $NGINX_CONF${NC}"
    rm -f "$NGINX_CONF"
fi

# Kiểm tra sự tồn tại của template NGINX
if is_file_exist "$NGINX_TEMPLATE"; then
    # Kiểm tra sự tồn tại của thư mục template
    if [ ! -d "$(dirname "$NGINX_TEMPLATE")" ]; then
        echo -e "${RED}❌ Thư mục chứa template NGINX không tồn tại: $(dirname "$NGINX_TEMPLATE")${NC}"
        exit 1
    fi

    # Tạo bản sao của template NGINX và thay thế các biến
    cp "$NGINX_TEMPLATE" "$NGINX_CONF" || { echo -e "${RED}❌ Không thể sao chép template NGINX.${NC}"; exit 1; }
    sedi "s|\\\${SITE_NAME}|$site_name|g" "$NGINX_CONF"
    sedi "s|\\\${DOMAIN}|$domain|g" "$NGINX_CONF"
    sedi "s|\\\${PHP_CONTAINER}|$site_name-php|g" "$NGINX_CONF"

    echo -e "${GREEN}✅ Đã tạo file NGINX: $NGINX_CONF${NC}"
else
    echo -e "${RED}❌ Không tìm thấy template NGINX: $NGINX_TEMPLATE${NC}"
    exit 1
fi
