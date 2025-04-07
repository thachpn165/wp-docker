#!/usr/bin/env bash

# ============================================
# 📝 website_management_info.sh – Show Website Information Logic
# ============================================

# === website_management_info_logic ===
website_management_info_logic() {
    local domain="$1"
    local site_dir="$SITES_DIR/$domain"
    local env_file="$site_dir/.env"
    local domain
    local db_name
    local db_user
    local db_pass

    # Check if website exists
    if ! is_directory_exist "$site_dir"; then
        print_and_debug error "$ERROR_NOT_EXIST: $domain"
        return 1
    fi

    # Check if .env file exists
    if ! is_file_exist "$env_file"; then
        print_and_debug error "$ERROR_ENV_NOT_FOUND: $env_file"
        return 1
    fi

    # Fetch website information from .env
    domain=$(fetch_env_variable "$env_file" "DOMAIN")
    db_name=$(fetch_env_variable "$env_file" "MYSQL_DATABASE")
    db_user=$(fetch_env_variable "$env_file" "MYSQL_USER")
    db_pass=$(fetch_env_variable "$env_file" "MYSQL_PASSWORD")


    # Display website information
    #echo -e "${GREEN}Website Information for '$domain':${NC}"
    print_msg label "$LABEL_WEBSITE_INFO: $domain"
    print_msg sub-label "$LABEL_WEBSITE_DOMAIN: $domain"
    print_msg sub-label "$LABEL_WEBSITE_DB_NAME: $db_name"
    print_msg sub-label "$LABEL_WEBSITE_DB_USER: $db_user"
    print_msg sub-label "$LABEL_WEBSITE_DB_PASS: $db_pass"
    print_msg sub-label "$LABEL_SITE_DIR: $site_dir"

}