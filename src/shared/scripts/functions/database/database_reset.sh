#!/bin/bash
# ==================================================
# File: database_reset.sh
# Description: Functions to reset WordPress site databases, including prompting the user 
#              to select a site and resetting the database by dropping and recreating it.
# Functions:
#   - database_prompt_reset: Prompt the user to select a site and perform a database reset.
#       Parameters: None.
#   - database_logic_reset: Reset the database for a given domain by dropping and recreating it.
#       Parameters:
#           $1 - domain: The domain name of the website to reset the database for.
# ==================================================

safe_source "$CLI_DIR/database_actions.sh"

database_prompt_reset() {
    local domain
    website_get_selected domain
    if [[ -z "$domain" ]]; then
        print_msg error "$ERROR_SITE_NOT_SELECTED"
        exit 1
    fi
    _is_valid_domain "$domain" || return 1

    # Trigger the reset logic via CLI wrapper
    database_cli_reset --domain="$domain"
}

database_logic_reset() {
    local domain="$1"

    _is_valid_domain "$domain" || return 1

    # Retrieve DB credentials and container info
    local db_name db_user db_password db_container
    db_name="$(json_get_site_value "$domain" "db_name")"
    db_user="$(json_get_site_value "$domain" "db_user")"
    db_password="$(json_get_site_value "$domain" "db_pass")"
    db_container="$MYSQL_CONTAINER_NAME"
    debug_log "[DB RESET] db_name=$db_name, db_user=$db_user"

    # Check if the MariaDB container is running
    if ! core_mysql_check_running; then
        print_msg error "$ERROR_DOCKER_CONTAINER_DB_NOT_RUNNING"
        return 1
    fi

    # Confirm the reset operation with the user
    print_msg important "$(printf "$QUESTION_DB_RESET_CONFIRM" "$db_name" "$domain")"
    confirm=$(get_input_or_test_value "$CONFIRM_DB_RESET" "${TEST_VALUE:-y}")
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        print_msg cancel "$MSG_OPERATION_CANCELLED"
        return 0
    fi

    # Perform DB reset (drop and recreate)
    print_msg step "$(printf "$STEP_DB_RESETTING" "$db_name" "$domain")"
    if ! docker exec -i --env MYSQL_PWD="$db_password" "$db_container" \
        mysql -u"$db_user" -e "DROP DATABASE IF EXISTS \`$db_name\`; CREATE DATABASE \`$db_name\`;"; then
        print_msg error "$(printf "$ERROR_DB_RESET_FAILED" "$db_name")"
        return 1
    fi

    # Success message
    print_msg success "$(printf "$SUCCESS_DB_RESET_DONE" "$db_name")"
}