#!/bin/bash

CONFIG_FILE="shared/config/config.sh"
source "$CONFIG_FILE"

# Nhập tên website
read -p "Nhập tên website: " site_name
SITE_DIR="$SITES_DIR/$site_name"
CACHE_CONF_DIR="$NGINX_PROXY_DIR/conf.d/cache"
NGINX_CONF_FILE="$NGINX_PROXY_DIR/conf.d/${site_name}.conf"

# Kiểm tra website tồn tại
if [ ! -d "$SITE_DIR" ]; then
    echo -e "${RED}❌ Website không tồn tại!${NC}"
    exit 1
fi

# Hiển thị danh sách cache
echo -e "${YELLOW}🔧 Chọn loại cache mới cho website:${NC}"
echo -e "  ${GREEN}[1]${NC} WP Super Cache"
echo -e "  ${GREEN}[2]${NC} FastCGI Cache"
echo -e "  ${GREEN}[3]${NC} Redis Cache"
echo -e "  ${GREEN}[4]${NC} W3 Total Cache"
echo -e "  ${GREEN}[5]${NC} Không có cache"
echo ""

read -p "Chọn loại cache (1-5): " cache_choice
case $cache_choice in
    1) cache_type="wp-super-cache" ;;
    2) cache_type="fastcgi-cache" ;;
    3) cache_type="redis-cache" ;;
    4) cache_type="w3-total-cache" ;;
    5) cache_type="no-cache" ;;
    *) echo -e "${RED}⚠️ Lựa chọn không hợp lệ!${NC}" && exit 1 ;;
esac

# ✅ **Cập nhật `include` trong NGINX**
if grep -q "include /etc/nginx/conf.d/cache/" "$NGINX_CONF_FILE"; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|include /etc/nginx/conf.d/cache/.*;|include /etc/nginx/conf.d/cache/${cache_type}.conf;|" "$NGINX_CONF_FILE"
    else
        sed -i "s|include /etc/nginx/conf.d/cache/.*;|include /etc/nginx/conf.d/cache/${cache_type}.conf;|" "$NGINX_CONF_FILE"
    fi
    echo -e "${GREEN}✅ Cấu hình NGINX đã được cập nhật: $cache_type${NC}"
else
    echo -e "${RED}❌ Lỗi: Không tìm thấy dòng include cache trong cấu hình NGINX!${NC}"
    exit 1
fi

# Restart NGINX để áp dụng cấu hình mới
docker exec nginx-proxy nginx -s reload
echo -e "${GREEN}✅ NGINX đã được reload để áp dụng cache mới.${NC}"
