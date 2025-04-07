#!/bin/bash

# === Logic: Reset database ===
database_reset_logic() {
    local domain="$1"

    # Validate domain
    if [[ -z "$domain" ]]; then
        print_and_debug error "$ERROR_PARAM_SITE_NAME_REQUIRED"
        return 1
    fi

    # Fetch DB credentials
    local db_info db_name db_user db_password
    db_info=$(db_fetch_env "$domain")
    if [[ $? -ne 0 ]]; then
        print_and_debug error "$(printf "$ERROR_DB_FETCH_CREDENTIALS" "$domain")"
        return 1
    fi
    IFS=' ' read -r db_name db_user db_password <<< "$db_info"
    debug_log "[DB RESET] db_name=$db_name, db_user=$db_user"

    # Check DB container status
    if ! is_mariadb_running "$domain"; then
        print_and_debug error "$ERROR_DOCKER_CONTAINER_DB_NOT_RUNNING: ${domain}-mariadb"
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
    if ! docker exec -i --env MYSQL_PWD="$db_password" ${domain}-mariadb \
        mysql -u$db_user -e "DROP DATABASE IF EXISTS $db_name; CREATE DATABASE $db_name;"; then
        print_msg error "$(printf "$ERROR_DB_RESET_FAILED" "$db_name")"
        return 1
    fi

    print_msg success "$(printf "$SUCCESS_DB_RESET_DONE" "$db_name")"
}
