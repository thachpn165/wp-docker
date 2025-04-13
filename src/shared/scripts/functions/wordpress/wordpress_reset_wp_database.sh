#!/bin/bash

# =====================================
# wordpress_reset_wp_database_logic: Reset WordPress database for a specific site
# Parameters:
#   $1 - domain (site name)
# Behavior:
#   - Validates site exists in .config.json
#   - Fetches database credentials
#   - Calls utility function to reset database
# =====================================
wordpress_reset_wp_database_logic() {
    local domain="$1"  # site_name passed from CLI or menu

    # ✅ Validate site exists in JSON
    if ! json_key_exists ".site[\"$domain\"]"; then
        print_msg error "$ERROR_WEBSITE_NOT_EXIST: $domain"
        return 1
    fi

    # 🔐 Fetch database credentials from .config.json
    local db_name db_user db_pass
    db_name=$(json_get_site_value "$domain" "MYSQL_DATABASE")
    db_user=$(json_get_site_value "$domain" "MYSQL_USER")
    db_pass=$(json_get_site_value "$domain" "MYSQL_PASSWORD")

    # 🔄 Call utility to reset database
    db_reset_database "$domain" "$db_user" "$db_pass" "$db_name"
}