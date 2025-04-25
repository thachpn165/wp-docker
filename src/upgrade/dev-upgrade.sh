source "../shared/config/load_config.sh"
load_config_file
# =============================================
# 🔧 WP Docker - Dev Upgrade Script
# v1.2.0: Switch to thachpn165/wpdocker-openresty
# =============================================

print_msg step "🔄 Đang nâng cấp image OpenResty cho docker-compose..."

# Đường dẫn docker-compose NGINX
local_compose="$NGINX_PROXY_DIR/docker-compose.yml"

if [[ ! -f "$local_compose" ]]; then
    print_msg error "❌ Không tìm thấy file: $local_compose"
    exit 1
fi

# Thay thế image trong docker-compose.yml
sedi 's|openresty/openresty:1.21.4.1-alpine|thachpn165/wpdocker-openresty|g' "$local_compose"
print_msg success "✅ Đã thay thế image OpenResty trong docker-compose.yml"

# Stop, remove và khởi động lại container nginx-proxy
print_msg step "🛑 Dừng container NGINX Proxy..."
cd "$NGINX_PROXY_DIR" || exit 1
docker compose stop nginx-proxy || true

print_msg step "🧹 Xóa container NGINX Proxy cũ..."
docker compose rm -f nginx-proxy || true

print_msg step "🚀 Khởi động lại container NGINX Proxy với image mới..."
docker compose up -d nginx-proxy
cd "$BASE_DIR" || exit 1
print_msg success "✅ Đã nâng cấp image OpenResty thành công!"
