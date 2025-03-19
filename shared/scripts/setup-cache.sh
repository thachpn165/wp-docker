#!/bin/bash

CONFIG_FILE="shared/config/config.sh"
source "$CONFIG_FILE"

# Nhập tên website
read -p "Nhập tên website: " site_name
SITE_DIR="$SITES_DIR/$site_name"
CACHE_CONF_DIR="$NGINX_PROXY_DIR/cache"
NGINX_CONF_FILE="$NGINX_PROXY_DIR/conf.d/${site_name}.conf"
WP_CONFIG_FILE="$SITE_DIR/wordpress/wp-config.php"
REDIS_CONTAINER="redis-cache"
PHP_CONTAINER="$site_name-php"
NGINX_MAIN_CONF="/etc/nginx/nginx.conf"

# Kiểm tra website tồn tại
if [ ! -d "$SITE_DIR" ]; then
    echo -e "${RED}❌ Website không tồn tại!${NC}"
    exit 1
fi

# Hiển thị danh sách cache
echo -e "${YELLOW}🔧 Chọn loại cache mới cho website:${NC}"
echo -e "  ${GREEN}[1]${NC} WP Super Cache"
echo -e "  ${GREEN}[2]${NC} FastCGI Cache"
echo -e "  ${GREEN}[3]${NC} FastCGI Cache + Redis Object Cache"
echo -e "  ${GREEN}[4]${NC} W3 Total Cache"
echo -e "  ${GREEN}[5]${NC} Không có cache"
echo ""

read -p "Chọn loại cache (1-5): " cache_choice
case $cache_choice in
    1) cache_type="wp-super-cache"; plugin_slug="wp-super-cache" ;;
    2) cache_type="fastcgi-cache"; plugin_slug="nginx-helper" ;;
    3) cache_type="fastcgi-cache"; plugin_slug="redis-cache nginx-helper" ;;
    4) cache_type="w3-total-cache"; plugin_slug="w3-total-cache" ;;
    5) cache_type="no-cache" ;;
    *) echo -e "${RED}⚠️ Lựa chọn không hợp lệ!${NC}" && exit 1 ;;
esac

# ✅ **Cập nhật `include` trong NGINX**
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

# Cài đặt plugin cache
if [[ "$cache_type" != "no-cache" ]]; then
    for plugin in $plugin_slug; do
        docker exec -u root "$PHP_CONTAINER" wp plugin install $plugin --activate --path=/var/www/html --allow-root
    done
    echo -e "${GREEN}✅ Plugin cache đã được cài đặt và kích hoạt.${NC}"
fi


# ✅ Cấu hình FastCGI Cache
if [[ "$cache_choice" == "2" || "$cache_choice" == "3" ]]; then
    echo -e "${YELLOW}⚡ Cấu hình FastCGI Cache...${NC}"

    # Kiểm tra nếu fastcgi_cache_path đã tồn tại, nếu có thì bỏ qua
    if ! docker exec nginx-proxy grep -q "fastcgi_cache_path" "$NGINX_MAIN_CONF"; then
        if docker exec nginx-proxy grep -q "http {" "$NGINX_MAIN_CONF"; then
            echo -e "${YELLOW}➕ Chèn fastcgi_cache_path vào http {}...${NC}"
            docker exec nginx-proxy sed -i "/http {/a\\
            fastcgi_cache_path /var/cache/nginx/fastcgi_cache levels=1:2 keys_zone=WORDPRESS:100m inactive=60m use_temp_path=off;
            " "$NGINX_MAIN_CONF"
        else
            echo -e "${RED}❌ Không tìm thấy block http {} trong nginx.conf! Hãy kiểm tra lại cấu hình.${NC}"
            exit 1
        fi
    fi
    echo -e "${GREEN}✅ FastCGI Cache đã được cấu hình.${NC}"
fi

# ✅ **Kiểm tra `<?php` trong `wp-config.php` trước khi chèn**
if ! grep -q "<?php" "$WP_CONFIG_FILE"; then
    echo -e "${RED}❌ Lỗi: Không tìm thấy `<?php` trong wp-config.php!${NC}"
    exit 1
fi

# Cấu hình Redis Object Cache (chỉ nếu chọn FastCGI Cache + Redis)
if [[ "$cache_choice" == "3" ]]; then
    echo -e "${YELLOW}⚡ Cấu hình Redis Object Cache...${NC}"

    # 🛠️ Kiểm tra và chèn `WP_REDIS_HOST` vào ngay sau `<?php`
    if ! grep -q "WP_REDIS_HOST" "$WP_CONFIG_FILE"; then
        echo -e "${YELLOW}🔧 Chèn cấu hình Redis vào wp-config.php...${NC}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "/<?php/a\\
            define('WP_REDIS_HOST', 'redis-cache');\\
            define('WP_REDIS_PORT', 6379);\\
            define('WP_REDIS_DATABASE', 0);
            " "$WP_CONFIG_FILE"
        else
            sed -i "/<?php/a\\
            define('WP_REDIS_HOST', 'redis-cache');\\
            define('WP_REDIS_PORT', 6379);\\
            define('WP_REDIS_DATABASE', 0);
            " "$WP_CONFIG_FILE"
        fi
        echo -e "${GREEN}✅ Cấu hình Redis đã được thêm vào wp-config.php.${NC}"
    fi

    # 🛠️ Kiểm tra và chèn `WP_CACHE` ngay sau `<?php`
    if grep -q "define('WP_CACHE', false);" "$WP_CONFIG_FILE"; then
        echo -e "${YELLOW}🔄 Cập nhật WP_CACHE thành true...${NC}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|define('WP_CACHE', false);|define('WP_CACHE', true);|" "$WP_CONFIG_FILE"
        else
            sed -i "s|define('WP_CACHE', false);|define('WP_CACHE', true);|" "$WP_CONFIG_FILE"
        fi
    elif ! grep -q "define('WP_CACHE'" "$WP_CONFIG_FILE"; then
        echo -e "${YELLOW}➕ Chèn WP_CACHE vào wp-config.php...${NC}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "/<?php/a\\
            define('WP_CACHE', true);
            " "$WP_CONFIG_FILE"
        else
            sed -i "/<?php/a\\
            define('WP_CACHE', true);
            " "$WP_CONFIG_FILE"
        fi
    fi
fi
# Bật Redis Cache nếu có Redis Object Cache
if [[ "$cache_choice" == "3" ]]; then
    echo -e "${YELLOW}⚡ Bật Redis Object Cache...${NC}"
    docker exec -u root "$PHP_CONTAINER" wp redis enable --path=/var/www/html --allow-root
    echo -e "${GREEN}✅ Redis Object Cache đã được bật.${NC}"
fi



# Restart NGINX để áp dụng cấu hình mới
docker exec nginx-proxy nginx -s reload
echo -e "${GREEN}✅ NGINX đã được reload để áp dụng cache mới.${NC}"
