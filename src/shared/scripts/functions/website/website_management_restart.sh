# =====================================
# 🔄 website_management_restart_logic – Logic to Restart WordPress Website
# =====================================

website_management_restart_logic() {
  site_list=($(ls -1 "$SITES_DIR"))

  if [ ${#site_list[@]} -eq 0 ]; then
    echo -e "${RED}❌ No websites available to restart.${NC}"
    return 1
  fi

  if [[ "$TEST_MODE" != true ]]; then
    echo -e "${YELLOW}📋 List of websites that can be restarted:${NC}"
    for i in "${!site_list[@]}"; do
      echo -e "  ${GREEN}[$i]${NC} ${site_list[$i]}"
    done
    read -p "Enter the number corresponding to the website to restart: " site_index
  else
    # In TEST_MODE, auto select the first site
    site_index=0
  fi

  site_name="${site_list[$site_index]}"

  if [ -z "$site_name" ]; then
    echo -e "${RED}❌ Invalid selection.${NC}"
    return 1
  fi

  echo -e "${YELLOW}🔄 Restarting website: $site_name...${NC}"
  docker compose -f "$SITES_DIR/$site_name/docker-compose.yml" restart
  echo -e "${GREEN}✅ Website '$site_name' has been restarted.${NC}"
}