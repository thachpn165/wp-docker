# =====================================
# 🔍 website_management_info – View website configuration information
# =====================================

website_management_info() {
  echo -e "${YELLOW}📋 List of available websites:${NC}"
  site_list=($(ls -1 "$SITES_DIR"))

  if [ ${#site_list[@]} -eq 0 ]; then
    echo -e "${RED}❌ No websites available to view information.${NC}"
    return 1
  fi

  for i in "${!site_list[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${site_list[$i]}"
  done

  echo ""
  read -p "Enter the number corresponding to the website to view information: " site_index
  site_name="${site_list[$site_index]}"

  SITE_DIR="$SITES_DIR/$site_name"
  ENV_FILE="$SITE_DIR/.env"

  if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}❌ .env file not found for site '$site_name'!${NC}"
    return 1
  fi

  echo -e "${CYAN}🔎 Website information: $site_name${NC}"
  echo -e "-------------------------------------------"
  grep -E '^(DOMAIN|PHP_VERSION|MYSQL_DATABASE|MYSQL_USER)' "$ENV_FILE" \
    | sed 's/^/  🔹 /'
  echo -e "-------------------------------------------"
}
