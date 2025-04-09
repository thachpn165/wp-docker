#!/usr/bin/env bash

# ============================================
# 📝 website_management_info.sh – Show Website Information Logic
# ============================================

# === website_management_info_logic ===
website_management_info_logic() {
    local domain="$1"
    local site_dir="$SITES_DIR/$domain"
    local db_name db_user db_pass

    # Check if website exists
    if ! is_directory_exist "$site_dir"; then
        print_and_debug error "$ERROR_NOT_EXIST: $domain"
        return 1
    fi

    # Fetch website information from .config.json
    db_name=$(json_get_site_value "$domain" "MYSQL_DATABASE")
    db_user=$(json_get_site_value "$domain" "MYSQL_USER")
    db_pass=$(json_get_site_value "$domain" "MYSQL_PASSWORD")

    # Display website information
    print_msg label "$LABEL_WEBSITE_INFO: $domain"
    print_msg sub-label "$LABEL_WEBSITE_DOMAIN: $domain"
    print_msg sub-label "$LABEL_WEBSITE_DB_NAME: $db_name"
    print_msg sub-label "$LABEL_WEBSITE_DB_USER: $db_user"
    print_msg sub-label "$LABEL_WEBSITE_DB_PASS: $db_pass"
    print_msg sub-label "$LABEL_SITE_DIR: $site_dir"
}