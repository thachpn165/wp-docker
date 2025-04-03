# Display list of websites for selection
select_website() {
    if [[ -z "$SITES_DIR" ]]; then
        echo -e "${RED}${CROSSMARK} SITES_DIR is not defined.${NC}"
        return 1
    fi

    local sites=()
    while IFS= read -r -d '' dir; do
        sites+=("$(basename "$dir")")
    done < <(find "$SITES_DIR" -mindepth 1 -maxdepth 1 -type d -print0)

    if [[ ${#sites[@]} -eq 0 ]]; then
        echo -e "${RED}${CROSSMARK} No websites found in $SITES_DIR${NC}"
        return 1
    fi

    if [[ "$TEST_MODE" == true ]]; then
        SITE_NAME="${TEST_SITE_NAME:-${sites[0]}}"
        echo -e "${YELLOW}🧪 TEST_MODE: auto-selecting $SITE_NAME${NC}"
    else
        echo -e "\n📄 Available websites:"
        for i in "${!sites[@]}"; do
            echo "  $((i+1)). ${sites[$i]}"
        done

        SELECTED_WEBSITE=$(select_from_list "🔹 Select a website:" "${sites[@]}")
        if [[ -z "$SELECTED_WEBSITE" ]]; then
            echo -e "${RED}${CROSSMARK} Invalid selection!${NC}"
            return 1
        fi

        SITE_NAME="$SELECTED_WEBSITE"
    fi

    echo -e "${GREEN}${CHECKMARK} Selected: $SITE_NAME${NC}"
}





# 🔍 Scan site list from sites directory
get_site_list() {
  find "$SITES_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
}

# =====================================
# ♻️ website_restore_from_archive – Restore Website from Archive Directory
# =====================================

website_restore_from_archive() {
  ARCHIVE_DIR="$BASE_DIR/archives/old_website"

  if [[ ! -d "$ARCHIVE_DIR" ]]; then
    echo -e "${RED}${CROSSMARK} Archive directory not found: $ARCHIVE_DIR${NC}"
    return 1
  fi

  echo -e "${YELLOW}📦 List of archived websites:${NC}"
  archive_list=( $(ls -1 "$ARCHIVE_DIR") )

  if [ ${#archive_list[@]} -eq 0 ]; then
    echo -e "${RED}${CROSSMARK} No websites available to restore.${NC}"
    return 1
  fi

  for i in "${!archive_list[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${archive_list[$i]}"
  done

  echo ""
  [[ "$TEST_MODE" != true ]] && read -p "Select site to restore (number): " archive_index
  selected_folder="${archive_list[$archive_index]}"
  archive_path="$ARCHIVE_DIR/$selected_folder"

  site_name=$(echo "$selected_folder" | cut -d '-' -f1)
  restore_target="$SITES_DIR/$site_name"

  if [[ -d "$restore_target" ]]; then
    echo -e "${RED}${CROSSMARK} Directory $restore_target already exists. Cannot overwrite.${NC}"
    return 1
  fi

  mkdir -p "$restore_target/wordpress" "$restore_target/logs" "$restore_target/backups" "$restore_target/php" "$restore_target/mariadb"

  echo -e "${YELLOW}📂 Extracting WordPress source code...${NC}"
  tar -xzf "$archive_path/${site_name}_wordpress.tar.gz" -C "$restore_target/wordpress"

  echo -e "${YELLOW}🛠️ Restoring database...${NC}"
  cp "$archive_path/${site_name}_db.sql" "$restore_target/backups/${site_name}_db.sql"

  echo -e "${GREEN}${CHECKMARK} Successfully restored source code and database.${NC}"
  echo -e "${YELLOW}👉 Please recreate the .env file and configure docker-compose to run the site.${NC}"

  [[ "$TEST_MODE" != true ]] && read -p "Would you like to open the newly restored site directory? (y/N): " open_choice
  if [[ "$open_choice" =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}📁 Path: $restore_target${NC}"
    ls -al "$restore_target"
  fi
}