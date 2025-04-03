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

# 📋 **Hiển thị danh sách website để chọn**
echo -e "${YELLOW}${WARNING} Tính năng này sẽ thiết lập lại quyền Administrator trên website về mặc định.${NC}"
echo -e "${YELLOW}${WARNING} Được dùng trong trường hợp website bị lỗi tài khoản Admin bị thiếu/mất quyền.${NC}"
echo -e "${BLUE}📋 Danh sách các website có thể reset quyền Admin:${NC}"
# 📋 Hiển thị danh sách website để chọn (dùng select_website)
select_website
if [[ -z "$domain" ]]; then
  echo -e "${RED}${CROSSMARK} No website selected.${NC}"
  exit 1
fi


SITE_DIR="$SITES_DIR/$domain"
PHP_CONTAINER="$domain-php"

# Truyền tham số vào CLI
bash "$SCRIPTS_DIR/cli/wordpress_reset_user_role.sh" --domain="$domain"
