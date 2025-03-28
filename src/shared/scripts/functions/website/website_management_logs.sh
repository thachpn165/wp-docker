# =====================================
# 📄 website_management_logs – View WordPress Website Logs
# =====================================

website_management_logs() {
  echo -e "${YELLOW}📋 List of websites to view logs:${NC}"
  site_list=($(ls -1 "$SITES_DIR"))

  if [ ${#site_list[@]} -eq 0 ]; then
    echo -e "${RED}❌ No websites available to view logs.${NC}"
    return 1
  fi

  for i in "${!site_list[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${site_list[$i]}"
  done

  echo ""
  read -p "Enter the number corresponding to the website to view logs: " site_index
  site_name="${site_list[$site_index]}"

  log_file="$SITES_DIR/$site_name/logs/access.log"
  error_log="$SITES_DIR/$site_name/logs/error.log"

  echo -e "${CYAN}📂 Which type of log would you like to view?${NC}"
  echo -e "  ${GREEN}[1]${NC} 📜 Access Log"
  echo -e "  ${GREEN}[2]${NC} 📛 Error Log"
  read -p "Select an option (1-2): " log_choice

  echo -ne "${YELLOW}⏳ Loading log"; for i in {1..5}; do echo -n "."; sleep 0.2; done; echo "${NC}"

  case "$log_choice" in
    1)
      echo -e "\n${CYAN}📜 Following Access Log: $log_file${NC}"
      echo -e "${YELLOW}💡 Press Ctrl + C to exit log following mode.${NC}\n"
      tail -f "$log_file"
      ;;
    2)
      echo -e "\n${MAGENTA}📛 Following Error Log: $error_log${NC}"
      echo -e "${YELLOW}💡 Press Ctrl + C to exit log following mode.${NC}\n"
      tail -f "$error_log"
      ;;
    *)
      echo -e "${RED}❌ Invalid option.${NC}"
      ;;
  esac
}
