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
[[ "$TEST_MODE" != true ]] && read -p "Nhập số tương ứng với website bạn muốn cài đặt cache: " site_index
site_name="${site_list[$site_index]}"

# ✅ Xác định thư mục & tập tin cần thao tác
SITE_DIR="$SITES_DIR/$site_name"
CACHE_CONF_DIR="$NGINX_PROXY_DIR/cache"
NGINX_CONF_FILE="$NGINX_PROXY_DIR/conf.d/${site_name}.conf"
WP_CONFIG_FILE="$SITE_DIR/wordpress/wp-config.php"
PHP_CONTAINER="$site_name-php"
NGINX_MAIN_CONF="/usr/local/openresty/nginx/conf/nginx.conf"

# ✅ Kiểm tra website có tồn tại không
if [ ! -d "$SITE_DIR" ]; then
    echo -e "${RED}❌ Website không tồn tại!${NC}"
    exit 1
fi

# ✅ Hiển thị menu cache
echo -e "${YELLOW}🔧 Chọn loại cache mới cho website:${NC}"
echo -e "  ${GREEN}[1]${NC} WP Super Cache"
echo -e "  ${GREEN}[2]${NC} FastCGI Cache & Redis Object Cache"
echo -e "  ${GREEN}[3]${NC} W3 Total Cache"
echo -e "  ${GREEN}[4]${NC} WP Fastest Cache"
echo -e "  ${GREEN}[5]${NC} Không có cache (Tắt tất cả)"
echo ""

[[ "$TEST_MODE" != true ]] && read -p "Chọn loại cache (1-5): " cache_choice
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
active_plugins=$(docker_exec_php "wp plugin list --status=active --field=name --path=/var/www/html")

for plugin in "${cache_plugins[@]}"; do
    if echo "$active_plugins" | grep -q "$plugin"; then
        echo -e "${YELLOW}⚠️ Plugin $plugin đang hoạt động, sẽ bị vô hiệu hoá.${NC}"
        docker_exec_php "wp plugin deactivate $plugin --path=/var/www/html"
    fi
done

# ✅ Nếu chọn tắt cache hoàn toàn thì xoá plugin cache và tắt WP_CACHE
if [[ "$cache_type" == "no-cache" ]]; then
    echo -e "${YELLOW}🧹 Gỡ plugin cache và xoá WP_CACHE...${NC}"
    for plugin in "${cache_plugins[@]}"; do
        docker_exec_php "wp plugin deactivate $plugin --path=/var/www/html"
        docker_exec_php "wp plugin delete $plugin --path=/var/www/html"
    done
    sedi "/define('WP_CACHE', true);/d" "$WP_CONFIG_FILE"
    if grep -q "include /etc/nginx/cache/" "$NGINX_CONF_FILE"; then
        sedi "s|include /etc/nginx/cache/.*;|include /etc/nginx/cache/no-cache.conf;|" "$NGINX_CONF_FILE"
    fi
    docker exec nginx-proxy nginx -s reload || { echo "❌ Command failed at line 74"; exit 1; }
    echo -e "${GREEN}✅ Đã tắt cache và reload NGINX.${NC}"
    exit 0
fi

# ✅ Cập nhật file cấu hình NGINX để include đúng cache
if grep -q "include /etc/nginx/cache/" "$NGINX_CONF_FILE"; then
    sedi "s|include /etc/nginx/cache/.*;|include /etc/nginx/cache/${cache_type}.conf;|" "$NGINX_CONF_FILE"
    echo -e "${GREEN}✅ Cập nhật cấu hình NGINX: $cache_type${NC}"
else
    echo -e "${RED}❌ Không tìm thấy dòng include cache trong cấu hình NGINX!${NC}"
    exit 1
fi

# ✅ Cài plugin cache mới
docker_exec_php "wp plugin install $plugin_slug --activate --path=/var/www/html"
docker exec -u root -i "$PHP_CONTAINER" chown -R nobody:nogroup /var/www/html/wp-content || { echo "❌ Command failed at line 90"; exit 1; }

# ✅ **Kiểm tra `<?php` trong `wp-config.php` trước khi chèn**
if ! grep -q "<?php" "$WP_CONFIG_FILE"; then
    echo -e "${RED}❌ Lỗi: Không tìm thấy `<?php` trong wp-config.php!${NC}"
    exit 1
fi

# ✅ Nếu cần, cấu hình FastCGI Cache trong nginx.conf
if [[ "$cache_choice" == "2" || "$cache_choice" == "3" ]]; then
    if ! docker exec nginx-proxy grep -q "fastcgi_cache_path" "$NGINX_MAIN_CONF"; then
        docker exec nginx-proxy sed -i "/http {/a\\ || { echo "❌ Command failed at line 101"; exit 1; }
        fastcgi_cache_path /var/cache/nginx/fastcgi_cache levels=1:2 keys_zone=WORDPRESS:100m inactive=60m use_temp_path=off;" "$NGINX_MAIN_CONF"
    fi
    echo -e "${GREEN}✅ FastCGI Cache đã được cấu hình.${NC}"
    docker_exec_php "wp option update rt_wp_nginx_helper_options '{\"enable_purge\":true}' --format=json --path=/var/www/html"
fi

# ✅ Cấu hình Redis Object Cache nếu chọn FastCGI
if [[ "$cache_choice" == "2" ]]; then
    if ! grep -q "WP_REDIS_HOST" "$WP_CONFIG_FILE"; then
        sedi "/<?php/a\\
        define('WP_REDIS_HOST', 'redis-cache');\\
        define('WP_REDIS_PORT', 6379);\\
        define('WP_REDIS_DATABASE', 0);" "$WP_CONFIG_FILE"
    fi
    docker_exec_php "wp plugin install redis-cache --activate --path=/var/www/html"
    docker_exec_php "wp redis update-dropin --path=/var/www/html"
    docker_exec_php "wp redis enable --path=/var/www/html"
    if grep -q "define('WP_CACHE', false);" "$WP_CONFIG_FILE"; then
        sedi "s|define('WP_CACHE', false);|define('WP_CACHE', true);|" "$WP_CONFIG_FILE"
    elif ! grep -q "define('WP_CACHE'" "$WP_CONFIG_FILE"; then
        sedi "/<?php/a\\
        define('WP_CACHE', true);" "$WP_CONFIG_FILE"
    fi
    echo -e "${GREEN}✅ Redis Object Cache đã cấu hình xong.${NC}"
fi

docker exec nginx-proxy nginx -s reload || { echo "❌ Command failed at line 128"; exit 1; }

echo -e "${GREEN}✅ NGINX đã được reload để áp dụng cache mới.${NC}"


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
nginx_reload
echo -e "${GREEN}✅ NGINX đã được reload để áp dụng cache mới.${NC}"
