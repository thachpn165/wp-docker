# ============================================
# 📘 mysql_utils.sh – MySQL Utility Functions
# ============================================
# Description:
#   - This script contains utility functions for managing MySQL databases and users
#     within a Docker container environment.
#
# Functions:
#   - mysql_get_root_passwd: Retrieve the MySQL root password.
#       Parameters: None
#   - mysql_exec: Execute a MySQL command in the container.
#       Parameters: $1 - command (the MySQL command to be executed)
#   - mysql_logic_create_db_name: Create a database with a standardized name.
#       Parameters: $1 - domain, $2 - db_name
#   - mysql_logic_create_db_user: Create a MySQL user for the database.
#       Parameters: $1 - domain, $2 - db_user, $3 - db_password
#   - mysql_logic_grant_all_privileges: Grant all privileges to a user on a database.
#       Parameters: $1 - db_name, $2 - db_user
#   - mysql_logic_delete_db_and_user: Delete a database and its associated user.
#       Parameters: $1 - domain, $2 - db_name, $3 - db_user
#   - core_mysql_check_running: Check if the MySQL container is running.
#       Parameters: None
# ============================================

mysql_get_root_passwd() {
    json_get_value '.mysql.root_password' "$JSON_CONFIG_FILE"
}

mysql_exec() {
    local command="$1"
    _is_container_running "$MYSQL_CONTAINER_NAME" || {
        print_msg error "$ERROR_DOCKER_CONTAINER_DB_NOT_RUNNING"
        return 1
    }
    docker exec --env MYSQL_PWD="$(mysql_get_root_passwd)" \
        "$MYSQL_CONTAINER_NAME" \
        mysql -uroot -e "$command"
    debug_log "[DB EXEC] $command"
}

mysql_logic_create_db_name() {
    local domain="$1"
    local db_name="$2"
    local sitename
    sitename=$(generate_sitename_from_domain "$domain")
    local final_db_name="${sitename}_${db_name}"

    json_set_site_value "$domain" "db_name" "$final_db_name"
    debug_log "[DB CREATE] db_name=$final_db_name"
    
    _is_container_running "$MYSQL_CONTAINER_NAME" || {
        print_and_debug error "$ERROR_DOCKER_CONTAINER_DB_NOT_RUNNING"
        return 1
    }
    if mysql_exec "SHOW DATABASES LIKE '$final_db_name';" | grep -q "$final_db_name"; then
        print_and_debug error "❌ Database \"$final_db_name\" already exists."
        return 1
    fi

    mysql_exec "CREATE DATABASE IF NOT EXISTS \`$final_db_name\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    print_msg success "$SUCCESS_DB_CREATED: $final_db_name"
}

mysql_logic_create_db_user() {
    local domain="$1"
    local db_user="$2"
    local db_password="$3"
    local sitename
    sitename=$(generate_sitename_from_domain "$domain")
    local final_db_user="${sitename}_${db_user}"

    json_set_site_value "$domain" "db_user" "$final_db_user"
    json_set_site_value "$domain" "db_pass" "$db_password"

    _is_container_running "$MYSQL_CONTAINER_NAME" || {
        print_and_debug error "$ERROR_DOCKER_CONTAINER_DB_NOT_RUNNING"
        return 1
    }
    if mysql_exec "SELECT User FROM mysql.user WHERE User = '$final_db_user';" | grep -q "$final_db_user"; then
        msg_print error "❌ Database user \"$final_db_user\" already exists."
        return 1
    fi

    mysql_exec "CREATE USER IF NOT EXISTS '$final_db_user'@'%' IDENTIFIED BY '$db_password';"
    print_msg success "$SUCCESS_DB_USER_CREATED: $final_db_user"
}

mysql_logic_grant_all_privileges() {
    local db_name="$1"
    local db_user="$2"
    _is_container_running "$MYSQL_CONTAINER_NAME" || {
        print_msg error "$ERROR_DOCKER_CONTAINER_DB_NOT_RUNNING"
        return 1
    }
    mysql_exec "GRANT ALL PRIVILEGES ON \`$db_name\`.* TO '$db_user'@'%'; FLUSH PRIVILEGES;"
}

mysql_logic_delete_db_and_user() {
    local domain="$1"
    local db_name="$2"
    local db_user="$3"
    local formatted_confirm_delete_db
    formatted_confirm_delete_db="$(printf "$QUESTION_DB_DELETE_CONFIRM" "$db_name" "$db_user")"
    if ! confirm_action "$formatted_confirm_delete_db"; then
        print_msg warning "⚠️ Skip deleting MySQL database and user for $domain"
        return 0
    fi
    _is_container_running "$MYSQL_CONTAINER_NAME" || {
        print_msg error "$ERROR_DOCKER_CONTAINER_DB_NOT_RUNNING"
        return 1
    }
    mysql_exec "DROP DATABASE IF EXISTS \`$db_name\`; DROP USER IF EXISTS '$db_user'@'%';"

    json_delete_site_field "$domain" "db_name"
    json_delete_site_field "$domain" "db_user"
    json_delete_site_field "$domain" "db_pass"
    print_msg success "$SUCCESS_DB_DELETED: $db_name"
    print_msg success "$SUCCESS_DB_USER_DELETED: $db_user"
}

core_mysql_check_running() {
    docker inspect -f '{{.State.Running}}' "$MYSQL_CONTAINER_NAME" 2>/dev/null | grep -q true
}
