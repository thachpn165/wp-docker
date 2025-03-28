# =====================================
# 🔄 website_management_restart – Restart WordPress Website
# =====================================

website_management_restart() {
  echo -e "${YELLOW}📋 List of websites that can be restarted:${NC}"
  site_list=($(ls -1 "$SITES_DIR"))

  if [ ${#site_list[@]} -eq 0 ]; then
    echo -e "${RED}❌ No websites available to restart.${NC}"
    return 1
  fi

  for i in "${!site_list[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${site_list[$i]}"
  done

  echo ""
  read -p "Enter the number corresponding to the website to restart: " site_index
  site_name="${site_list[$site_index]}"

  if [ -z "$site_name" ]; then
    echo -e "${RED}❌ Invalid selection.${NC}"
    return 1
  fi

  echo -e "${YELLOW}🔄 Restarting website: $site_name...${NC}"
  docker compose -f "$SITES_DIR/$site_name/docker-compose.yml" restart
  echo -e "${GREEN}✅ Website '$site_name' has been restarted.${NC}"
}