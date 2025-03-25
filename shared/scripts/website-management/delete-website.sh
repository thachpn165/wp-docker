#!/bin/bash

# =====================================
# 🗑️ Script xóa website WordPress
# =====================================

CONFIG_FILE="shared/config/config.sh"

# 🔍 Load config.sh theo thư mục cha nếu chưa thấy
while [ ! -f "$CONFIG_FILE" ]; do
    CONFIG_FILE="../$CONFIG_FILE"
    if [ "$(pwd)" = "/" ]; then
        echo "❌ Lỗi: Không tìm thấy config.sh!" >&2
        exit 1
    fi
done
source "$CONFIG_FILE"

# ✅ Kiểm tra biến cần thiết
required_vars=("PROJECT_ROOT" "SITES_DIR" "NGINX_PROXY_DIR" "SSL_DIR" "NGINX_PROXY_CONTAINER")
check_required_envs "${required_vars[@]}"

# 📋 Hiển thị danh sách website
echo -e "${YELLOW}📋 Danh sách các website có thể xóa:${NC}"
site_list=( $(ls -1 "$SITES_DIR") )

if [ ${#site_list[@]} -eq 0 ]; then
    echo -e "${RED}❌ Không có website nào để xóa.${NC}"
    exit 1
fi

for i in "${!site_list[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${site_list[$i]}"
done

read -p "Nhập số tương ứng với website cần xóa: " site_index
site_name="${site_list[$site_index]}"
SITE_DIR="$SITES_DIR/$site_name"
ENV_FILE="$SITE_DIR/.env"

if ! is_directory_exist "$SITE_DIR"; then
    echo -e "${RED}❌ Website '$site_name' không tồn tại.${NC}"
    exit 1
fi

if ! is_file_exist "$ENV_FILE"; then
    echo -e "${RED}❌ Không tìm thấy file .env của website!${NC}"
    exit 1
fi

DOMAIN=$(fetch_env_variable "$ENV_FILE" "DOMAIN")
MARIADB_VOLUME="${site_name}_mariadb_data"
SITE_CONF_FILE="$NGINX_PROXY_DIR/conf.d/$site_name.conf"

# 🚨 Cảnh báo và xác nhận
clear
echo -e "${RED}${BOLD}🚨 CẢNH BÁO QUAN TRỌNG 🚨${NC}"
echo -e "${RED}❗ Việc xóa website là KHÔNG THỂ HOÀN TÁC ❗${NC}"
echo -e "${YELLOW}📌 Hãy backup dữ liệu trước khi tiếp tục.${NC}"
echo

if ! confirm_action "⚠️ Bạn có chắc muốn xóa website '$site_name' ($DOMAIN)?"; then
    echo -e "${YELLOW}⚠️ Đã hủy thao tác xóa.${NC}"
    exit 0
fi

if confirm_action "🗑️ Xóa mã nguồn WordPress?"; then
    delete_source=true
else
    delete_source=false
fi

if confirm_action "🗑️ Xóa volume database MariaDB?"; then
    delete_db=true
else
    delete_db=false
fi

# 🧹 Xoá container PHP và MariaDB (nếu đang chạy độc lập)
docker rm -f "$site_name-php" "$site_name-mariadb" 2>/dev/null || true

# 🧹 Thực hiện xóa docker compose (nếu có)
cd "$SITE_DIR"
docker compose --project-name "$site_name" down 2>/dev/null || true
cd "$PROJECT_ROOT"

# 🔥 Xoá mã nguồn
if [ "$delete_source" = true ]; then
    remove_directory "$SITE_DIR"
    echo -e "${GREEN}✅ Đã xóa thư mục website: $SITE_DIR${NC}"
fi

# 🔥 Xoá SSL cert
remove_file "$SSL_DIR/$DOMAIN.crt"
remove_file "$SSL_DIR/$DOMAIN.key"
echo -e "${GREEN}✅ Đã xóa chứng chỉ SSL (nếu có).${NC}"

# 🔥 Xoá volume DB
if [ "$delete_db" = true ]; then
    remove_volume "$MARIADB_VOLUME"
    echo -e "${GREEN}✅ Đã xóa volume DB: $MARIADB_VOLUME${NC}"
fi

# 🔥 Xoá cấu hình NGINX
if is_file_exist "$SITE_CONF_FILE"; then
    remove_file "$SITE_CONF_FILE"
    echo -e "${GREEN}✅ Đã xóa file cấu hình NGINX.${NC}"
fi

# 🧹 Xóa mount entry trong docker-compose.override.yml
OVERRIDE_FILE="$NGINX_PROXY_DIR/docker-compose.override.yml"
MOUNT_ENTRY="      - ../sites/$site_name/wordpress:/var/www/$site_name"
MOUNT_LOGS="      - ../sites/$site_name/logs:/var/www/logs/$site_name"

if [ -f "$OVERRIDE_FILE" ]; then
    temp_file=$(mktemp)
    grep -vF "$MOUNT_ENTRY" "$OVERRIDE_FILE" | grep -vF "$MOUNT_LOGS" > "$temp_file"
    mv "$temp_file" "$OVERRIDE_FILE"
    echo -e "${GREEN}✅ Đã xóa website '$site_name' và logs khỏi docker-compose.override.yml.${NC}"
else
    echo -e "${YELLOW}⚠️ Không tìm thấy docker-compose.override.yml, bỏ qua.${NC}"
fi

# 🔥 Xoá cronjob nếu có
if crontab -l 2>/dev/null | grep -q "$site_name"; then
    tmp_cron=$(mktemp)
    crontab -l | grep -v "$site_name" > "$tmp_cron"
    crontab "$tmp_cron"
    rm -f "$tmp_cron"
    echo -e "${GREEN}✅ Đã xóa cronjob liên quan đến site.${NC}"
fi

# 🔄 Reload NGINX
restart_nginx_proxy

echo -e "${GREEN}✅ Website '$site_name' đã được xoá hoàn toàn.${NC}"
read -p "Nhấn Enter để quay lại menu..."