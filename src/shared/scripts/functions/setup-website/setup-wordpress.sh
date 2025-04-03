#!/bin/bash

# =====================================
# 📣 Script to install WordPress for the created website
# =====================================

# === Auto-detect PROJECT_DIR ===
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


# === Check input ===
site_name="${1:-}"
if [[ -z "$domain" ]]; then
  echo -e "${RED}${CROSSMARK} Missing site name.${NC}"
  exit 1
fi

# === Tìm .env và thông tin site ===
# (giữ lại toàn bộ đoạn xử lý ENV_FILE...)

# === Hỏi người dùng tạo user mạnh hay nhập tay ===
[[ "$TEST_MODE" != true ]] && read -p "👤 Use strong auto-generated admin account? [Y/n]: " auto_gen
auto_gen="${auto_gen:-Y}"
auto_gen="$(echo "$auto_gen" | tr '[:upper:]' '[:lower:]')"

if [[ "$auto_gen" == "n" ]]; then
  [[ "$TEST_MODE" != true ]] && read -p "👤 Enter admin username: " ADMIN_USER
  ...
else
  ADMIN_USER="admin-..."
  ADMIN_PASSWORD="..."
  ADMIN_EMAIL="admin@$domain.local"
fi

# === Gọi hàm xử lý cài WordPress ===
source "$FUNCTIONS_DIR/website/website_setup_wordpress.sh"
website_setup_wordpress "$domain" "$ADMIN_USER" "$ADMIN_PASSWORD" "$ADMIN_EMAIL"