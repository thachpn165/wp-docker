mysql_get_root_passwd() {
    # ============================================
    # 📘 mysql_get_root_passwd – Retrieve the MySQL root password
    # ============================================
    # Description:
    #   - This function fetches the MySQL root password from the JSON configuration file.
    #
    # Parameters:
    #   - None
    #
    # Globals:
    #   - JSON_CONFIG_FILE
    #
    # Returns:
    #   - The MySQL root password as a string.
    # ============================================
    json_get_value '.mysql.root_password' "$JSON_CONFIG_FILE"
}

mysql_exec() {
    # ============================================
    # 📘 mysql_exec – Execute a MySQL command in the container
    # ============================================
    # Description:
    #   - This function runs a given MySQL command inside the Docker container
    #     using the MySQL root password for authentication.
    #
    # Parameters:
    #   - $1 - command (the MySQL command to be executed)
    #
    # Globals:
    #   - MYSQL_CONTAINER_NAME
    #
    # Returns:
    #   - None
    # ============================================
    local command="$1"
    docker exec --env MYSQL_PWD="$(mysql_get_root_passwd)" \
        "$MYSQL_CONTAINER_NAME" \
        mysql -uroot -e "$command"
}

mysql_logic_create_db_name() {
    # ============================================
    # 📘 mysql_logic_create_db_name – Create a database with a standardized name
    # ============================================
    # Description:
    #   - This function creates a new MySQL database with a name based on the
    #     provided domain and a specified suffix. It also checks if the database
    #     already exists before attempting to create it.
    #
    # Parameters:
    #   - $1 - domain (the domain associated with the database)
    #   - $2 - db_name (the suffix for the database name)
    #
    # Globals:
    #   - None
    #
    # Returns:
    #   - 1 if the database already exists, otherwise 0.
    # ============================================
    local domain="$1"
    local db_name="$2"
    local sitename
    sitename=$(generate_sitename_from_domain "$domain")
    local final_db_name="${sitename}_${db_name}"

    json_set_site_value "$domain" "db_name" "$final_db_name"

    # Check if the database already exists
    if mysql_exec "SHOW DATABASES LIKE '$final_db_name';" | grep -q "$final_db_name"; then
        msg_print error "❌ Database \"$final_db_name\" already exists."
        return 1
    fi

    mysql_exec "CREATE DATABASE IF NOT EXISTS \`$final_db_name\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
}

mysql_logic_create_db_user() {
    # ============================================
    # 📘 mysql_logic_create_db_user – Create a MySQL user for the database
    # ============================================
    # Description:
    #   - This function creates a new MySQL user with a password and associates
    #     it with the specified domain. It checks if the user already exists
    #     before attempting to create it.
    #
    # Parameters:
    #   - $1 - domain (the domain associated with the user)
    #   - $2 - db_user (the username to be created)
    #   - $3 - db_password (the password for the user)
    #
    # Globals:
    #   - None
    #
    # Returns:
    #   - 1 if the user already exists, otherwise 0.
    # ============================================
    local domain="$1"
    local db_user="$2"
    local db_password="$3"
    local sitename
    sitename=$(generate_sitename_from_domain "$domain")
    local final_db_user="${sitename}_${db_user}"

    json_set_site_value "$domain" "db_user" "$final_db_user"
    json_set_site_value "$domain" "db_pass" "$db_password"

    # Check if the user already exists
    if mysql_exec "SELECT User FROM mysql.user WHERE User = '$final_db_user';" | grep -q "$final_db_user"; then
        msg_print error "❌ Database user \"$final_db_user\" already exists."
        return 1
    fi

    mysql_exec "CREATE USER IF NOT EXISTS '$final_db_user'@'%' IDENTIFIED BY '$db_password';"
}

mysql_logic_grant_all_privileges() {
    # ============================================
    # 📘 mysql_logic_grant_all_privileges – Grant all privileges to a user on a database
    # ============================================
    # Description:
    #   - This function grants all privileges on a specified database to
    #     a given user in MySQL.
    #
    # Parameters:
    #   - $1 - db_name (the name of the database)
    #   - $2 - db_user (the username to grant privileges to)
    #
    # Globals:
    #   - None
    #
    # Returns:
    #   - None
    # ============================================
    local db_name="$1"
    local db_user="$2"
    mysql_exec "GRANT ALL PRIVILEGES ON \`$db_name\`.* TO '$db_user'@'%'; FLUSH PRIVILEGES;"
}

mysql_logic_delete_db_and_user() {
    # ============================================
    # 📘 mysql_logic_delete_db_and_user – Delete a database and its associated user
    # ============================================
    # Description:
    #   - This function deletes a specified MySQL database and its associated
    #     user after confirming the action with the user.
    #
    # Parameters:
    #   - $1 - domain (the domain associated with the database and user)
    #   - $2 - db_name (the name of the database to be deleted)
    #   - $3 - db_user (the username to be deleted)
    #
    # Globals:
    #   - None
    #
    # Returns:
    #   - 0 if the action is skipped, otherwise none.
    # ============================================
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
    # ============================================
    # 📘 core_mysql_check_running – Check if the MySQL container is running
    # ============================================
    # Description:
    #   - This function checks the state of the MySQL Docker container to
    #     determine if it is currently running.
    #
    # Parameters:
    #   - None
    #
    # Globals:
    #   - MYSQL_CONTAINER_NAME
    #
    # Returns:
    #   - true if the container is running, otherwise false.
    # ============================================
    # return true if the container is running
    docker inspect -f '{{.State.Running}}' "$MYSQL_CONTAINER_NAME" 2>/dev/null | grep -q true
}