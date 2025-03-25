# =====================================
# 📋 website_management_list – Hiển thị danh sách website hiện có
# =====================================

website_management_list() {
  if [[ ! -d "$SITES_DIR" ]]; then
    echo -e "${RED}❌ Thư mục $SITES_DIR không tồn tại.${NC}"
    return 1
  fi

  site_list=($(ls -1 "$SITES_DIR"))

  echo -e "${YELLOW}📋 Danh sách các website hiện có:${NC}"

  if [ ${#site_list[@]} -eq 0 ]; then
    echo -e "${RED}❌ Không có website nào được cài đặt.${NC}"
    return 0
  fi

  for i in "${!site_list[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${site_list[$i]}"
  done

  echo -e "${GREEN}✅ Hiển thị danh sách website hoàn tất.${NC}"
  read -p "Nhấn Enter để quay lại menu..."
}
