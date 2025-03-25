# =====================================
# 🔄 website_management_restart – Restart website WordPress
# =====================================

website_management_restart() {
  echo -e "${YELLOW}📋 Danh sách các website có thể restart:${NC}"
  site_list=($(ls -1 "$SITES_DIR"))

  if [ ${#site_list[@]} -eq 0 ]; then
    echo -e "${RED}❌ Không có website nào để restart.${NC}"
    return 1
  fi

  for i in "${!site_list[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${site_list[$i]}"
  done

  echo ""
  read -p "Nhập số tương ứng với website cần restart: " site_index
  site_name="${site_list[$site_index]}"

  if [ -z "$site_name" ]; then
    echo -e "${RED}❌ Lựa chọn không hợp lệ.${NC}"
    return 1
  fi

  echo -e "${YELLOW}🔄 Đang restart website: $site_name...${NC}"
  docker compose -f "$SITES_DIR/$site_name/docker-compose.yml" restart
  echo -e "${GREEN}✅ Website '$site_name' đã được restart.${NC}"
}