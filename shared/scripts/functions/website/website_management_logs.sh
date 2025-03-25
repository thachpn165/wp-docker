# =====================================
# 📄 website_management_logs – Xem logs website WordPress
# =====================================

website_management_logs() {
  echo -e "${YELLOW}📋 Danh sách các website có thể xem logs:${NC}"
  site_list=($(ls -1 "$SITES_DIR"))

  if [ ${#site_list[@]} -eq 0 ]; then
    echo -e "${RED}❌ Không có website nào để xem logs.${NC}"
    return 1
  fi

  for i in "${!site_list[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${site_list[$i]}"
  done

  echo ""
  read -p "Nhập số tương ứng với website cần xem logs: " site_index
  site_name="${site_list[$site_index]}"

  log_file="$SITES_DIR/$site_name/logs/access.log"
  error_log="$SITES_DIR/$site_name/logs/error.log"

  echo -e "${CYAN}📂 Bạn muốn xem loại log nào?${NC}"
  echo -e "  ${GREEN}[1]${NC} 📜 Access Log"
  echo -e "  ${GREEN}[2]${NC} 📛 Error Log"
  read -p "Chọn một tuỳ chọn (1-2): " log_choice

  echo -ne "${YELLOW}⏳ Đang tải log"; for i in {1..5}; do echo -n "."; sleep 0.2; done; echo "${NC}"

  case "$log_choice" in
    1)
      echo -e "\n${CYAN}📜 Đang theo dõi Access Log: $log_file${NC}"
      echo -e "${YELLOW}💡 Nhấn Ctrl + C để thoát khỏi chế độ theo dõi logs.${NC}\n"
      tail -f "$log_file"
      ;;
    2)
      echo -e "\n${MAGENTA}📛 Đang theo dõi Error Log: $error_log${NC}"
      echo -e "${YELLOW}💡 Nhấn Ctrl + C để thoát khỏi chế độ theo dõi logs.${NC}\n"
      tail -f "$error_log"
      ;;
    *)
      echo -e "${RED}❌ Tuỳ chọn không hợp lệ.${NC}"
      ;;
  esac
}
