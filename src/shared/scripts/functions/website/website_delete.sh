#!/bin/bash
# ==================================================
# File: website_delete.sh
# Description: Functions to delete a WordPress website, including:
#              - Prompting the user for confirmation and optional backup.
#              - Stopping containers, removing Docker volumes, NGINX mounts, SSL, crontab entries, and .config.json entries.
#              - Reloading NGINX after cleanup.
# Functions:
#   - website_prompt_delete: Prompt user to delete a WordPress site with optional backup.
#       Parameters: None.
#   - website_logic_delete: Logic to delete a WordPress website.
#       Parameters:
#           $1 - domain: Domain name of the website to delete.
#           $2 - backup_enabled: Whether to backup the website before deletion (true/false).
# ==================================================

website_prompt_delete() {
    # Prompt user to delete a WordPress site with optional backup.
    # Parameters: None.

    safe_source "$CLI_DIR/website_manage.sh"
    safe_source "$CLI_DIR/database_actions.sh"

    print_msg title "$TITLE_WEBSITE_DELETE"

    # Select website
    local domain
    if ! website_get_selected domain; then
        return 1
    fi
    _is_valid_domain "$domain" || return 1

    # Ask for backup before delete
    backup_enabled=true # default
    backup_confirm=$(get_input_or_test_value "💾 $PROMPT_BACKUP_BEFORE_DELETE $domain (${YELLOW}yes${NC}/${RED}no${NC}) " "yes")
    [[ "$backup_confirm" != "yes" ]] && backup_enabled=false
    debug_log "[DEBUG] Backup before delete: $backup_enabled"

    # Run deletion logic
    website_cli_delete \
        --domain="$domain" \
        --backup_enabled="$backup_enabled" || return 1
}

website_logic_delete() {
    # Logic to delete a WordPress website.
    # Parameters:
    #   $1 - domain: Domain name of the website to delete.
    #   $2 - backup_enabled: Whether to backup the website before deletion (true/false).

    safe_source "$CLI_DIR/backup_website.sh"
    local domain="$1"
    local backup_enabled="$2"

    if [[ -z "$domain" ]]; then
        website_prompt_delete
    fi
    _is_valid_domain "$domain" || return 1
    SITE_DIR="$SITES_DIR/$domain"

    # Ask for final delete confirmation
    delete_confirm=$(get_input_or_test_value "❗ $PROMPT_WEBSITE_DELETE_CONFIRM $domain (${YELLOW}yes${NC}/${RED}no${NC}) " "no")
    if [[ "$delete_confirm" != "yes" ]]; then
        print_msg warning "$WARNING_ACTION_CANCELLED"
        exit 0
    fi

    if ! _is_directory_exist "$SITE_DIR"; then
        print_msg warning "$WARNING_WEBSITE_DIR_MISSING: $SITE_DIR"
        print_msg warning "⛔️ Website directory is missing, will proceed to cleanup config and related data only."
    fi

    SITE_CONF_FILE="$NGINX_PROXY_DIR/conf.d/$domain.conf"

    debug_log "Deleting website '$domain'..."
    debug_log "Site conf file: $SITE_CONF_FILE"
    debug_log "Site directory: $SITE_DIR"
    debug_log "backup_enabled: $backup_enabled"

    if [[ "$backup_enabled" == true ]]; then
        print_msg step "$MSG_WEBSITE_BACKUP_BEFORE_REMOVE: $domain"

        local archive_file old_web_dir
        old_web_dir="$ARCHIVES_DIR/old_website/$domain"
        archive_file="$ARCHIVES_DIR/old_website/${domain}-$(date +%Y%m%d-%H%M%S)_${domain}_db.sql"
        _is_directory_exist "$old_web_dir" || mkdir -p "$old_web_dir"
        print_msg step "$MSG_WEBSITE_BACKING_UP_DB: $domain"
        database_cli_export --domain="$domain" --save_location="$archive_file"

        print_msg step "$MSG_WEBSITE_BACKING_UP_FILES: $SITE_DIR/wordpress"
        backup_cli_file --domain="$domain" true

        print_msg success "$MSG_WEBSITE_BACKUP_FILE_CREATED: $archive_file"
    fi

    print_msg step "$MSG_WEBSITE_STOPPING_CONTAINERS: $domain"
    run_cmd "docker compose -f $SITE_DIR/docker-compose.yml down" true
    debug_log "Stopped containers for website '$domain'."

    # Remove database/user if present in .config.json
    local db_name db_user
    db_name="$(json_get_site_value "$domain" "db_name")"
    db_user="$(json_get_site_value "$domain" "db_user")"

    if [[ -n "$db_name" && -n "$db_user" ]]; then
        mysql_logic_delete_db_and_user "$domain" "$db_name" "$db_user"
    fi

    OVERRIDE_FILE="$NGINX_PROXY_DIR/docker-compose.override.yml"
    MOUNT_ENTRY="      - ../../../../sites/$domain/wordpress:/var/www/$domain"
    MOUNT_LOGS="      - ../../../../sites/$domain/logs:/var/www/logs/$domain"

    if [[ -f "$OVERRIDE_FILE" ]]; then
        print_msg step "$MSG_NGINX_REMOVE_MOUNT: $domain"
        nginx_remove_mount_docker "$OVERRIDE_FILE" "$MOUNT_ENTRY" "$MOUNT_LOGS"
    fi

    print_msg step "$MSG_WEBSITE_DELETING_DIRECTORY: $SITE_DIR"
    remove_directory "$SITE_DIR"
    print_msg success "$SUCCESS_DIRECTORY_REMOVE: $SITE_DIR"

    print_msg step "$MSG_WEBSITE_DELETING_SSL: $domain"
    remove_file "$SSL_DIR/$domain.crt"
    remove_file "$SSL_DIR/$domain.key"
    print_msg success "$SUCCESS_SSL_CERTIFICATE_REMOVED: $domain"

    print_msg step "$MSG_WEBSITE_DELETING_NGINX_CONF: $SITE_CONF_FILE"
    remove_file "$SITE_CONF_FILE"
    print_msg success "$SUCCESS_FILE_REMOVED: $SITE_CONF_FILE"

    if crontab -l 2>/dev/null | grep -q "$domain"; then
        tmp_cron=$(mktemp)
        crontab -l | grep -v "$domain" >"$tmp_cron"
        crontab "$tmp_cron"
        rm -f "$tmp_cron"
        print_msg success "$SUCCESS_CRON_REMOVED: $domain"
    fi

    # Remove entry in .config.json
    json_delete_site_key "$domain"
    print_msg success "$SUCCESS_CONFIG_SITE_REMOVED: $domain"
    safe_source "$CORE_LIB_DIR/nginx_utils.sh"
    nginx_restart
    print_msg success "$SUCCESS_WEBSITE_REMOVED: $domain"
}