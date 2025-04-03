database_reset_logic() {
    local domain="$1"

    # Fetch database credentials from the website's .env file
    local db_info
    db_info=$(db_fetch_env "$domain")
    
    # Check if fetching database credentials was successful
    if [[ $? -ne 0 ]]; then
        echo "${CROSSMARK} Failed to fetch database credentials for site '$domain'."
        return 1
    fi

    # Parse the database credentials
    local db_name db_user db_password
    IFS=' ' read -r db_name db_user db_password <<< "$db_info"

    # Check if MariaDB container is running
    if ! is_mariadb_running "$domain"; then
        echo "${CROSSMARK} MariaDB container for site '$domain' is not running. Please check!"
        return 1
    fi

    # Warning and user confirmation
    echo "${IMPORTANT} WARNING: This will RESET the database '$db_name' for site '$domain'. All data in the database will be lost permanently!"
    read -rp "Are you sure you want to proceed? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "${CROSSMARK} Action canceled. No changes were made."
        return 0
    fi

    # Proceed to reset the database
    echo "${IMPORTANT}${NC} Resetting database: $db_name for site: $domain..."
    
    # Use --env to securely pass the password to the container
    docker exec -i --env MYSQL_PWD="$db_password" ${domain}-mariadb mysql -u$db_user -e "DROP DATABASE IF EXISTS $db_name; CREATE DATABASE $db_name;"

    if [[ $? -ne 0 ]]; then
        echo "${CROSSMARK} Failed to reset the database '$db_name'."
        return 1
    fi

    echo "${CHECKMARK} Database has been reset successfully!"
}