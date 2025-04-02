#!/usr/bin/env bash

# ============================================
# 📝 website_management_info.sh – Show Website Information Logic
# ============================================

# === website_management_info_logic ===
website_management_info_logic() {
    local site_name="$1"
    local site_dir="$SITES_DIR/$site_name"
    local env_file="$site_dir/.env"
    local domain
    local db_name
    local db_user
    local db_pass

    # Check if website exists
    if ! is_directory_exist "$site_dir"; then
        echo -e "${RED}${CROSSMARK} Website '$site_name' does not exist.${NC}"
        return 1
    fi

    # Check if .env file exists
    if ! is_file_exist "$env_file"; then
        echo -e "${RED}${CROSSMARK} .env file for website '$site_name' not found!${NC}"
        return 1
    fi

    # Fetch website information from .env
    domain=$(fetch_env_variable "$env_file" "DOMAIN")
    db_name=$(fetch_env_variable "$env_file" "MYSQL_DATABASE")
    db_user=$(fetch_env_variable "$env_file" "MYSQL_USER")
    db_pass=$(fetch_env_variable "$env_file" "MYSQL_PASSWORD")

    # Display website information
    echo -e "${GREEN}Website Information for '$site_name':${NC}"
    echo -e "  ${YELLOW}Domain:${NC} $domain"
    echo -e "  ${YELLOW}Database Name:${NC} $db_name"
    echo -e "  ${YELLOW}Database User:${NC} $db_user"
    echo -e "  ${YELLOW}Database Password:${NC} $db_pass"
}