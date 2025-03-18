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

# Kiểm tra biến quan trọng có tồn tại không
required_vars=("PROJECT_ROOT" "SITES_DIR" "PROXY_SCRIPT" "PROXY_CONF_DIR" "SSL_DIR")

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}❌ Lỗi: Biến '$var' chưa được định nghĩa trong config.sh${NC}"
        exit 1
    fi
done

echo -e "${YELLOW}📋 Danh sách các website có thể xóa:${NC}"
ls "$SITES_DIR"
echo ""

read -p "Nhập tên website cần xóa: " site_name

SITE_DIR="$SITES_DIR/$site_name"
ENV_FILE="$SITE_DIR/.env"

# **Kiểm tra xem website có tồn tại không**
if ! is_directory_exist "$SITE_DIR"; then
    echo -e "${RED}❌ Website '$site_name' không tồn tại!${NC}"
    exit 1
fi

# **Lấy thông tin domain từ .env**
if is_file_exist "$ENV_FILE"; then
    DOMAIN=$(fetch_env_variable "$ENV_FILE" "DOMAIN")
    mariadb_volume="${site_name}_mariadb_data"
else
    echo -e "${RED}❌ Không tìm thấy file .env của website!${NC}"
    exit 1
fi

SITE_CONF_FILE="$PROXY_CONF_DIR/$site_name.conf"

# 🚨 **Hiển thị cảnh báo**
clear
echo -e "${RED}${BOLD}🚨 CẢNH BÁO QUAN TRỌNG 🚨${NC}"
echo -e "${RED}❗ Việc xóa website là thao tác không thể hoàn tác! ❗${NC}"
echo -e "${YELLOW}📌 Vui lòng backup dữ liệu trước khi tiếp tục.${NC}"
echo ""

# **Xác nhận xóa website**
if ! confirm_action "⚠️ Bạn có chắc muốn xóa website '$site_name' ($DOMAIN)?"; then
    echo -e "${YELLOW}⚠️ Hủy thao tác xóa website '${site_name}'.${NC}"
    exit 0
fi

# **Hỏi người dùng có muốn xóa mã nguồn website không**
if confirm_action "⚠️ Bạn có muốn xóa toàn bộ mã nguồn WordPress của '$site_name'?"; then
    delete_source_flag=true
else
    delete_source_flag=false
fi

# **Hỏi người dùng có muốn xóa volume MariaDB không**
if confirm_action "⚠️ Bạn có muốn xóa volume database MariaDB của '$site_name'?"; then
    delete_mariadb_flag=true
else
    delete_mariadb_flag=false
fi

echo -e "${BLUE}🔄 Đang xóa website '$site_name'...${NC}"

# **Dừng & xóa container**
cd "$SITE_DIR"
docker-compose down
cd "$PROJECT_ROOT"

# **Xóa mã nguồn nếu người dùng chọn**
if [ "$delete_source_flag" = true ]; then
    remove_directory "$SITE_DIR"
    echo -e "${GREEN}✅ Mã nguồn WordPress của '$site_name' đã bị xóa!${NC}"
else
    echo -e "${YELLOW}⚠️ Giữ lại mã nguồn WordPress của '$site_name'.${NC}"
fi

# **Xóa volume MariaDB nếu người dùng chọn**
if [ "$delete_mariadb_flag" = true ]; then
    remove_volume "$mariadb_volume"
    echo -e "${GREEN}✅ Volume MariaDB của '$site_name' đã bị xóa!${NC}"
else
    echo -e "${YELLOW}⚠️ Giữ lại volume MariaDB của '$site_name'.${NC}"
fi

# **Xóa file cấu hình NGINX của website**
if is_file_exist "$SITE_CONF_FILE"; then
    echo -e "${YELLOW}🗑️ Đang xóa cấu hình NGINX của '$DOMAIN'...${NC}"
    remove_file "$SITE_CONF_FILE"
    echo -e "${GREEN}✅ Cấu hình NGINX của '$DOMAIN' đã được xóa.${NC}"
else
    echo -e "${RED}⚠️ Không tìm thấy file cấu hình $SITE_CONF_FILE. Bỏ qua.${NC}"
fi

# **Reload NGINX Proxy để cập nhật lại cấu hình**
restart_nginx_proxy

echo -e "${GREEN}✅ Hoàn tất xóa website '$site_name'.${NC}"

read -p "Nhấn Enter để quay lại menu..."
