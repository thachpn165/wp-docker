database_reset_logic() {
    local site_name="$1"

    # Fetch database credentials from the website's .env file
    local db_info
    db_info=$(db_fetch_env "$site_name")
    
    # Check if fetching database credentials was successful
    if [[ $? -ne 0 ]]; then
        echo "${CROSSMARK} Failed to fetch database credentials for site '$site_name'."
        return 1
    fi

    # Parse the database credentials
    local db_name db_user db_password
    IFS=' ' read -r db_name db_user db_password <<< "$db_info"

    # Check if MariaDB container is running
    if ! is_mariadb_running "$site_name"; then
        echo "${CROSSMARK} MariaDB container for site '$site_name' is not running. Please check!"
        return 1
    fi

    # Proceed to reset the database
    echo "🚨 Resetting database: $db_name for site: $site_name..."
    
    # Use --env to securely pass the password to the container
    docker exec -i --env MYSQL_PWD="$db_password" ${site_name}-mariadb mysql -u$db_user -e "DROP DATABASE IF EXISTS $db_name; CREATE DATABASE $db_name;"

    if [[ $? -ne 0 ]]; then
        echo "${CROSSMARK} Failed to reset the database '$db_name'."
        return 1
    fi

    echo "${CHECKMARK} Database has been reset successfully!"
}