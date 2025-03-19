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

# 📋 **Hiển thị danh sách website để chọn**
echo -e "${YELLOW}📋 Danh sách các website có thể reset database:${NC}"
site_list=($(ls -1 "$SITES_DIR"))

if [ ${#site_list[@]} -eq 0 ]; then
    echo -e "${RED}❌ Không có website nào để reset database.${NC}"
    exit 1
fi

for i in "${!site_list[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${site_list[$i]}"
done

echo ""
read -p "Nhập số tương ứng với website cần reset database: " site_index
site_name="${site_list[$site_index]}"

SITE_DIR="$SITES_DIR/$site_name"
ENV_FILE="$SITE_DIR/.env"

# 🚨 **Hiển thị cảnh báo quan trọng**
clear
echo -e "${RED}${BOLD}🚨 CẢNH BÁO QUAN TRỌNG 🚨${NC}"
echo -e "${RED}❗ Việc reset database sẽ xóa toàn bộ dữ liệu và không thể khôi phục! ❗${NC}"
echo -e "${YELLOW}📌 Vui lòng sao lưu đầy đủ trước khi tiếp tục.${NC}"
echo ""
read -p "Bạn có chắc chắn muốn tiếp tục reset database? (gõ 'RESET' để xác nhận): " confirm_reset

if [[ "$confirm_reset" != "RESET" ]]; then
    echo -e "${YELLOW}⚠️ Hủy thao tác reset database.${NC}"
    exit 0
fi

# **Lấy thông tin database từ .env**
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    echo -e "${RED}❌ Không tìm thấy file .env cho site '$site_name'!${NC}"
    exit 1
fi

# **Thực hiện reset database bằng hàm utils**
db_reset_database "$site_name" "$MYSQL_USER" "$MYSQL_PASSWORD" "$MYSQL_DATABASE"

echo -e "${GREEN}✅ Database đã được reset thành công!${NC}"

echo ""
# **Dừng lại cho đến khi người dùng nhấn Enter để thoát**
echo -e "${YELLOW}🔚 Nhấn Enter để thoát...${NC}"
read -r
