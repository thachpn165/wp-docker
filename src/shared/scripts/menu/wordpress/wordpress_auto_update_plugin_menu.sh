#!/bin/bash
# === Load config & website_loader.sh ===
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


# 📋 Hiển thị danh sách website để chọn (dùng select_website)
select_website
if [[ -z "$domain" ]]; then
  echo -e "${RED}${CROSSMARK} No website selected.${NC}"
  exit 1
fi


# 📋 **Lựa chọn hành động bật/tắt tự động cập nhật**
echo -e "${YELLOW}📋 Chọn hành động cho website '$domain':${NC}"
echo "1) Bật tự động cập nhật plugin"
echo "2) Tắt tự động cập nhật plugin"
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
bash "$SCRIPTS_DIR/cli/wordpress_auto_update_plugin.sh" --domain="$domain" --action="$action"
