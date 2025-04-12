#!/bin/bash
safe_source "$CLI_DIR/database_actions.sh"

database_prompt_reset() {
    # Ensure SITE_DOMAIN is set by calling select_website
    select_website || exit 1

    # Check if SITE_DOMAIN is still empty
    if [[ -z "$domain" ]]; then
        echo "${CROSSMARK} Site name is not set. Exiting..."
        exit 1
    fi

    # Call cli/database_reset.sh with the selected site_name as parameter
    database_cli_reset --domain="$domain"
}

database_logic_reset() {
    local domain="$1"

    # Validate domain
    if [[ -z "$domain" ]]; then
        print_and_debug error "$ERROR_PARAM_SITE_NAME_REQUIRED"
        return 1
    fi
    echo "domain: $domain"

    # Fetch DB credentials
    local  db_name db_user db_password
    db_name="$(json_get_site_value "$domain" "MYSQL_DATABASE")"
    db_user="$(json_get_site_value "$domain" "MYSQL_USER")"
    db_password="$(json_get_site_value "$domain" "MYSQL_PASSWORD")"
    db_container="$(json_get_site_value "$domain" "CONTAINER_DB")"
    echo "db_container: $db_container"
    debug_log "[DB RESET] db_name=$db_name, db_user=$db_user"

    # Check DB container status
    if ! is_mariadb_running "$domain"; then
        print_and_debug error "$ERROR_DOCKER_CONTAINER_DB_NOT_RUNNING: $db_container"
        return 1
    fi

    # Confirm with user
    print_msg important "$(printf "$QUESTION_DB_RESET_CONFIRM" "$db_name" "$domain")"
    confirm=$(get_input_or_test_value "$CONFIRM_DB_RESET" "${TEST_VALUE:-y}")
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        print_msg cancel "$MSG_OPERATION_CANCELLED"
        return 0
    fi

    # Proceed reset
    print_msg step "$(printf "$STEP_DB_RESETTING" "$db_name" "$domain")"
    if ! docker exec -i --env MYSQL_PWD="$db_password" $db_container \
        mysql -u$db_user -e "DROP DATABASE IF EXISTS $db_name; CREATE DATABASE $db_name;"; then
        print_msg error "$(printf "$ERROR_DB_RESET_FAILED" "$db_name")"
        return 1
    fi

    print_msg success "$(printf "$SUCCESS_DB_RESET_DONE" "$db_name")"
}
