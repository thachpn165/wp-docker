# =====================================
# 📋 website_management_list – Display List of Existing Websites
# =====================================

website_management_list_logic() {
  if [[ ! -d "$SITES_DIR" ]]; then
    echo -e "${RED}${CROSSMARK} Directory $SITES_DIR does not exist.${NC}"
    return 1
  fi

  site_list=($(ls -1 "$SITES_DIR"))

  echo -e "${YELLOW}📋 List of Existing Websites:${NC}"

  if [ ${#site_list[@]} -eq 0 ]; then
    echo -e "${RED}${CROSSMARK} No websites are installed.${NC}"
    return 0
  fi

  for i in "${!site_list[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${site_list[$i]}"
  done

  echo -e "${GREEN}${CHECKMARK} Website list display completed.${NC}"
}

website_management_list() {
  website_management_list_logic

  if [[ "$TEST_MODE" != true ]]; then
    read -p "Press Enter to return to menu..."
  fi
}
