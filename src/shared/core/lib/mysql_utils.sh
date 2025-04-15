mysql_get_root_passwd() {
    json_get_value '.mysql.root_password' "$JSON_CONFIG_FILE"
}

mysql_exec() {
    local command="$1"
    docker exec --env MYSQL_PWD="$(mysql_get_root_passwd)" \
        "$MYSQL_CONTAINER_NAME" \
        mysql -uroot -e "$command"
}


mysql_logic_create_db_name() {
    local domain="$1"
    local db_name="$2"
    local sitename
    sitename=$(generate_sitename_from_domain "$domain")
    local final_db_name="${sitename}_${db_name}"

    json_set_site_value "$domain" "db_name" "$final_db_name"

    # Kiểm tra nếu database đã tồn tại
    if mysql_exec "SHOW DATABASES LIKE '$final_db_name';" | grep -q "$final_db_name"; then
        msg_print error "❌ Database \"$final_db_name\" already exists."
        return 1
    fi

    mysql_exec "CREATE DATABASE IF NOT EXISTS \`$final_db_name\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
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

    # Kiểm tra nếu user đã tồn tại
    if mysql_exec "SELECT User FROM mysql.user WHERE User = '$final_db_user';" | grep -q "$final_db_user"; then
        msg_print error "❌ Database user \"$final_db_user\" already exists."
        return 1
    fi

    mysql_exec "CREATE USER IF NOT EXISTS '$final_db_user'@'%' IDENTIFIED BY '$db_password';"
}

mysql_logic_grant_all_privileges() {
    local db_name="$1"
    local db_user="$2"
    mysql_exec "GRANT ALL PRIVILEGES ON \`$db_name\`.* TO '$db_user'@'%'; FLUSH PRIVILEGES;"
}

mysql_logic_delete_db_and_user() {
    local domain="$1"
    local db_name="$2"
    local db_user="$3"

    if ! confirm_action "❓ Are you sure you want to delete database \"$db_name\" and user \"$db_user\"?"; then
        print_msg warning "⚠️ Skip deleting MySQL database and user for $domain"
        return 0
    fi

    mysql_exec "DROP DATABASE IF EXISTS \`$db_name\`; DROP USER IF EXISTS '$db_user'@'%';"

    json_delete_site_field "$domain" "db_name"
    json_delete_site_field "$domain" "db_user"
    json_delete_site_field "$domain" "db_pass"
}
core_mysql_check_running() {
    # return true if the container is running
    docker inspect -f '{{.State.Running}}' "$MYSQL_CONTAINER_NAME" 2>/dev/null | grep -q true
}