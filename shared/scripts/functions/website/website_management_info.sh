# =====================================
# 🔍 website_management_info – Xem thông tin cấu hình website
# =====================================

website_management_info() {
  echo -e "${YELLOW}📋 Danh sách các website có sẵn:${NC}"
  site_list=($(ls -1 "$SITES_DIR"))

  if [ ${#site_list[@]} -eq 0 ]; then
    echo -e "${RED}❌ Không có website nào để xem thông tin.${NC}"
    return 1
  fi

  for i in "${!site_list[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${site_list[$i]}"
  done

  echo ""
  read -p "Nhập số tương ứng với website cần xem thông tin: " site_index
  site_name="${site_list[$site_index]}"

  SITE_DIR="$SITES_DIR/$site_name"
  ENV_FILE="$SITE_DIR/.env"

  if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}❌ Không tìm thấy file .env cho site '$site_name'!${NC}"
    return 1
  fi

  echo -e "${CYAN}🔎 Thông tin website: $site_name${NC}"
  echo -e "-------------------------------------------"
  grep -E '^(DOMAIN|PHP_VERSION|MYSQL_DATABASE|MYSQL_USER)' "$ENV_FILE" \
    | sed 's/^/  🔹 /'
  echo -e "-------------------------------------------"
}
