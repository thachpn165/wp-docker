#!/bin/bash

# Ensure PROJECT_DIR is set
if [[ -z "$PROJECT_DIR" ]]; then
  SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
  
  # Iterate upwards from the current script directory to find 'config.sh'
  while [[ "$SCRIPT_PATH" != "/" ]]; do
    if [[ -f "$SCRIPT_PATH/shared/config/config.sh" ]]; then
      PROJECT_DIR="$SCRIPT_PATH"
      break
    fi
    SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
  done

  # Handle error if config file is not found
  if [[ -z "$PROJECT_DIR" ]]; then
    echo "${CROSSMARK} Unable to determine PROJECT_DIR. Please check the script's directory structure." >&2
    exit 1
  fi
fi

# Load the config file if PROJECT_DIR is set
CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "${CROSSMARK} Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi

# Source the config file
source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/wordpress_loader.sh"

# ${IMPORTANT}${NC} **Cảnh báo quan trọng**
clear
echo -e "${RED}${BOLD}${IMPORTANT}${NC} CẢNH BÁO QUAN TRỌNG ${IMPORTANT}${NC}${NC}"
echo -e "${RED}${ERROR} Việc reset database sẽ xóa toàn bộ dữ liệu và không thể khôi phục! ${ERROR}${NC}"
echo -e "${YELLOW}📌 Vui lòng sao lưu đầy đủ trước khi tiếp tục.${NC}"
echo ""

# 📋 **Hiển thị danh sách website để chọn**
echo -e "${YELLOW}📋 Danh sách các website có thể reset database:${NC}"
site_list=($(ls -1 "$SITES_DIR"))

if [ ${#site_list[@]} -eq 0 ]; then
    echo -e "${RED}${CROSSMARK} Không có website nào để thực hiện thao tác này.${NC}"
    exit 1
fi

for i in "${!site_list[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${site_list[$i]}"
done

echo ""
read -p "Nhập số tương ứng với website cần reset database: " site_index


# 📋 **Xác nhận hành động reset database**
echo -e "${YELLOW}📋 Bạn có chắc chắn muốn reset database cho website '$domain'?${NC}"
echo "1) Yes, reset database"
echo "2) NO"
read -p "Nhập số tương ứng với hành động: " confirm_choice

if [ "$confirm_choice" == "1" ]; then
    # Truyền tham số vào CLI để thực hiện reset database
    bash "$SCRIPTS_DIR/cli/wordpress_reset_wp_database.sh" --domain="$domain"
    echo -e "${GREEN}${CHECKMARK} Database đã được reset thành công cho website '$domain'.${NC}"
elif [ "$confirm_choice" == "2" ]; then
    echo -e "${YELLOW}${WARNING} Thao tác reset database đã bị hủy.${NC}"
else
    echo -e "${RED}${CROSSMARK} Lựa chọn không hợp lệ.${NC}"
    exit 1
fi
