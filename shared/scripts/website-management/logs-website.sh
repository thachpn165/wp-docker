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

# 🛠 **Kiểm tra biến quan trọng**
required_vars=("SITES_DIR")

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}❌ Lỗi: Biến '$var' chưa được định nghĩa trong config.sh${NC}"
        exit 1
    fi
done

# 📋 **Hiển thị danh sách website để chọn**
echo -e "${YELLOW}📋 Danh sách các website có thể xem logs:${NC}"
site_list=($(ls -1 "$SITES_DIR"))

if [ ${#site_list[@]} -eq 0 ]; then
    echo -e "${RED}❌ Không có website nào để xem logs.${NC}"
    exit 1
fi

for i in "${!site_list[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${site_list[$i]}"
done

echo ""
read -p "Nhập số tương ứng với website cần xem logs: " site_index
site_name="${site_list[$site_index]}"

LOGS_DIR="$SITES_DIR/$site_name/logs"

# **Kiểm tra thư mục logs có tồn tại không**
if ! is_directory_exist "$LOGS_DIR"; then
    echo -e "${RED}❌ Không tìm thấy thư mục logs của '$site_name'!${NC}"
    exit 1
fi

# 📌 **Chọn loại log để xem**
echo -e "${YELLOW}📋 Chọn loại logs để xem:${NC}"
echo -e "  ${GREEN}[1]${NC} Access Log (access.log)"
echo -e "  ${GREEN}[2]${NC} Error Log (error.log)"

echo ""
read -p "Nhập số tương ứng với loại logs cần xem: " log_choice

case $log_choice in
    1) log_file="$LOGS_DIR/access.log" ;;
    2) log_file="$LOGS_DIR/error.log" ;;
    *) echo -e "${RED}⚠️ Lựa chọn không hợp lệ!${NC}" && exit 1 ;;
esac

# **Hiển thị logs**
echo -e "${BLUE}📖 Đang hiển thị logs: $log_file${NC}"
tail -f "$log_file"