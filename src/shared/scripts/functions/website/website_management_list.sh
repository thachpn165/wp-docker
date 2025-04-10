# =====================================
# 📋 website_management_list – Display List of Existing Websites
# =====================================

# =====================================
# 📋 website_management_list – Display List of Existing Websites
# =====================================

website_management_list_logic() {
  if [[ ! -d "$SITES_DIR" ]]; then
    print_and_debug error "$MSG_NOT_FOUND: $SITES_DIR"
    return 1
  fi

  site_list=($(ls -1 "$SITES_DIR"))

  #echo -e "${YELLOW}📋 List of Existing Websites:${NC}"
  print_msg label "$LABEL_WEBSITE_LIST"
  if [ ${#site_list[@]} -eq 0 ]; then
    #echo -e "${RED}${CROSSMARK} No websites are installed.${NC}"
    print_msg error "$ERROR_NO_WEBSITES_FOUND"
    return 0
  fi

  for i in "${!site_list[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${site_list[$i]}"
  done
}

website_management_list() {
  website_management_list_logic
}
