#!/bin/bash

CONFIG_FILE="shared/config/config.sh"
source "$CONFIG_FILE"

# ✅ Hiển thị danh sách các website có sẵn
echo -e "${YELLOW}🔍 Danh sách website có sẵn:${NC}"
site_list=($(ls -1 "$SITES_DIR"))
for i in "${!site_list[@]}"; do
    echo -e "  ${GREEN}[${i}]${NC} ${site_list[$i]}"
done
echo ""

# ✅ Người dùng chọn website
read -p "Nhập số tương ứng với website bạn muốn cài đặt cache: " site_index
site_name="${site_list[$site_index]}"

# ✅ Xác định thư mục & tập tin cần thao tác
SITE_DIR="$SITES_DIR/$site_name"
CACHE_CONF_DIR="$NGINX_PROXY_DIR/cache"
NGINX_CONF_FILE="$NGINX_PROXY_DIR/conf.d/${site_name}.conf"
WP_CONFIG_FILE="$SITE_DIR/wordpress/wp-config.php"
PHP_CONTAINER="$site_name-php"
NGINX_MAIN_CONF="/etc/nginx/nginx.conf"

# ✅ Kiểm tra website có tồn tại không
if [ ! -d "$SITE_DIR" ]; then
    echo -e "${RED}❌ Website không tồn tại!${NC}"
    exit 1
fi

# ✅ Hiển thị menu cache
echo -e "${YELLOW}🔧 Chọn loại cache mới cho website:${NC}"
echo -e "  ${GREEN}[1]${NC} WP Super Cache"
echo -e "  ${GREEN}[2]${NC} FastCGI Cache"
echo -e "  ${GREEN}[3]${NC} W3 Total Cache"
echo -e "  ${GREEN}[4]${NC} WP Fastest Cache"
echo -e "  ${GREEN}[5]${NC} Không có cache (Tắt tất cả)"
echo ""

read -p "Chọn loại cache (1-4): " cache_choice
case $cache_choice in
    1) cache_type="wp-super-cache"; plugin_slug="wp-super-cache" ;;
    2) cache_type="fastcgi-cache"; plugin_slug="nginx-helper" ;;
    3) cache_type="w3-total-cache"; plugin_slug="w3-total-cache" ;;
    4) cache_type="wp-fastest-cache"; plugin_slug="wp-fastest-cache" ;;
    5) cache_type="no-cache" ;;
    *) echo -e "${RED}⚠️ Lựa chọn không hợp lệ!${NC}" && exit 1 ;;
esac

# ✅ Kiểm tra các plugin cache hiện tại và tắt nếu cần
cache_plugins=("wp-super-cache" "nginx-helper" "w3-total-cache" "redis-cache" "wp-fastest-cache")
active_plugins=$(docker exec -u root "$PHP_CONTAINER" wp plugin list --status=active --field=name --allow-root --path=/var/www/html)

for plugin in "${cache_plugins[@]}"; do
    if echo "$active_plugins" | grep -q "$plugin"; then
        echo -e "${YELLOW}⚠️ Plugin $plugin đang hoạt động, sẽ bị vô hiệu hoá trước khi kích hoạt plugin mới.${NC}"
        docker exec -u root "$PHP_CONTAINER" wp plugin deactivate "$plugin" --allow-root --path=/var/www/html
    fi
done

# ✅ Nếu chọn no-cache, xoá toàn bộ plugin cache và WP_CACHE
if [[ "$cache_type" == "no-cache" ]]; then
    echo -e "${YELLOW}🛑 Tắt toàn bộ plugin cache...${NC}"
    for plugin in "${cache_plugins[@]}"; do
        docker exec -u root "$PHP_CONTAINER" wp plugin deactivate "$plugin" --allow-root --path=/var/www/html
        docker exec -u root "$PHP_CONTAINER" wp plugin delete "$plugin" --allow-root --path=/var/www/html
    done

    echo -e "${YELLOW}🧹 Xoá \`WP_CACHE\` trong wp-config.php...${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "/define('WP_CACHE', true);/d" "$WP_CONFIG_FILE"
    else
        sed -i "/define('WP_CACHE', true);/d" "$WP_CONFIG_FILE"
    fi

    echo -e "${GREEN}✅ Tất cả plugin cache đã bị xoá và \`WP_CACHE\` đã bị gỡ bỏ.${NC}"
    exit 0
fi

# ✅ Cập nhật `include` trong NGINX nếu cần
if grep -q "include /etc/nginx/cache/" "$NGINX_CONF_FILE"; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|include /etc/nginx/cache/.*;|include /etc/nginx/cache/${cache_type}.conf;|" "$NGINX_CONF_FILE"
    else
        sed -i "s|include /etc/nginx/cache/.*;|include /etc/nginx/cache/${cache_type}.conf;|" "$NGINX_CONF_FILE"
    fi
    echo -e "${GREEN}✅ Cấu hình NGINX đã được cập nhật: $cache_type${NC}"
else
    echo -e "${RED}❌ Lỗi: Không tìm thấy dòng include cache trong cấu hình NGINX!${NC}"
    exit 1
fi

# ✅ Cài đặt plugin cache mới
if [[ "$cache_type" != "no-cache" ]]; then
    docker exec -u root "$PHP_CONTAINER" wp plugin install $plugin_slug --activate --path=/var/www/html --allow-root
    echo -e "${GREEN}✅ Plugin cache đã được cài đặt và kích hoạt: $plugin_slug${NC}"
fi

# ✅ Hướng dẫn kích hoạt WP Super Cache nếu cần
if [[ "$cache_type" == "wp-super-cache" ]]; then
    echo -e "${YELLOW}⚠️ Hướng dẫn hoàn tất cài đặt WP Super Cache:${NC}"
    echo -e "  1️⃣ Truy cập vào WordPress Admin -> Settings -> WP Super Cache."
    echo -e "  2️⃣ Bật 'Caching On' để kích hoạt cache."
    echo -e "  3️⃣ Chọn 'Expert' trong 'Cache Delivery Method'."
    echo -e "  4️⃣ Lưu cài đặt và kiểm tra cache hoạt động."
fi

# ✅ Hướng dẫn kích hoạt W3 Total Cache nếu cần
if [[ "$cache_type" == "w3-total-cache" ]]; then
    echo -e "${YELLOW}⚠️ Hướng dẫn hoàn tất cài đặt W3 Total Cache:${NC}"
    echo -e "  1️⃣ Truy cập vào WordPress Admin -> Performance -> General Settings."
    echo -e "  2️⃣ Bật tất cả các loại cache phù hợp (Page Cache, Object Cache, Database Cache)."
    echo -e "  3️⃣ Lưu cài đặt và kiểm tra cache hoạt động."
fi

# ✅ Hướng dẫn kích hoạt WP Fastest Cache nếu cần
if [[ "$cache_type" == "wp-fastest-cache" ]]; then
    echo -e "${YELLOW}⚠️ Hướng dẫn hoàn tất cài đặt WP Fastest Cache:${NC}"
    echo -e "  1️⃣ Truy cập vào WordPress Admin -> WP Fastest Cache."
    echo -e "  2️⃣ Bật tùy chọn 'Enable Cache'."
    echo -e "  3️⃣ Chọn 'Cache System' phù hợp."
    echo -e "  4️⃣ Lưu cài đặt và kiểm tra cache hoạt động."
fi

# ✅ Restart NGINX để áp dụng cấu hình mới
docker exec nginx-proxy nginx -s reload
echo -e "${GREEN}✅ NGINX đã được reload để áp dụng cache mới.${NC}"
