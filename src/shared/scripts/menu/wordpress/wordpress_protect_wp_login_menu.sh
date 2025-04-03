#!/bin/bash

# === Load config & system_loader.sh ===
if [[ -z "$PROJECT_DIR" ]]; then
  SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
  while [[ "$SCRIPT_PATH" != "/" ]]; do
    if [[ -f "$SCRIPT_PATH/shared/config/config.sh" ]]; then
      PROJECT_DIR="$SCRIPT_PATH"
      break
    fi
    SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
  done
fi

CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "${CROSSMARK} Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi
source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/wordpress_loader.sh"

# 📋 **Hiển thị danh sách website để chọn**
echo -e "${YELLOW}📋 Danh sách các website có thể bật/tắt bảo vệ wp-login.php:${NC}"
site_list=($(ls -1 "$SITES_DIR"))

if [ ${#site_list[@]} -eq 0 ]; then
    echo -e "${RED}${CROSSMARK} Không có website nào để thực hiện thao tác này.${NC}"
    exit 1
fi

for i in "${!site_list[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${site_list[$i]}"
done

echo ""
read -p "Nhập số tương ứng với website cần bật/tắt bảo vệ wp-login.php: " site_index
site_name="${site_list[$site_index]}"

# 📋 **Lựa chọn hành động bật/tắt bảo vệ wp-login.php**
echo -e "${YELLOW}📋 Chọn hành động cho website '$site_name':${NC}"
echo "1) Bật bảo vệ wp-login.php"
echo "2) Tắt bảo vệ wp-login.php"
read -p "Nhập số tương ứng với hành động: " action_choice

if [ "$action_choice" == "1" ]; then
    action="enable"
elif [ "$action_choice" == "2" ]; then
    action="disable"
else
    echo -e "${RED}${CROSSMARK} Lựa chọn không hợp lệ.${NC}"
    exit 1
fi

# Truyền tham số vào CLI
bash "$SCRIPTS_DIR/cli/wordpress_protect_wp_login.sh" --site_name="$site_name" --action="$action"
