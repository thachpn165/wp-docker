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
  echo "❌ Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi
source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/wordpress_loader.sh"

# 📋 **Hiển thị danh sách website để chọn**
echo -e "${YELLOW}⚠️ Tính năng này sẽ thiết lập lại quyền Administrator trên website về mặc định.${NC}"
echo -e "${YELLOW}⚠️ Được dùng trong trường hợp website bị lỗi tài khoản Admin bị thiếu/mất quyền.${NC}"
echo -e "${BLUE}📋 Danh sách các website có thể reset quyền Admin:${NC}"
site_list=($(ls -1 "$SITES_DIR"))

if [ ${#site_list[@]} -eq 0 ]; then
    echo -e "${RED}❌ Không có website nào để reset quyền Admin.${NC}"
    exit 1
fi

for i in "${!site_list[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${site_list[$i]}"
done

echo ""
read -p "Nhập số tương ứng với website cần reset quyền Admin: " site_index
site_name="${site_list[$site_index]}"

SITE_DIR="$SITES_DIR/$site_name"
PHP_CONTAINER="$site_name-php"

# Truyền tham số vào CLI
bash "$SCRIPTS_DIR/cli/wordpress_reset_user_role.sh" --site_name="$site_name"
