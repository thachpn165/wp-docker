# database_import_logic – Logic to import database (restore)
database_import_logic() {
    local domain="$1"
    local backup_file="$2"

    # Ensure PROJECT_DIR is set
    if [[ -z "$SITES_DIR" ]]; then
        echo "${CROSSMARK} SITES_DIR is not set. Ensure config.sh is sourced correctly."
        return 1
    fi

    # Ensure $domain is set
    if [[ -z "$domain" ]]; then
        echo "${CROSSMARK} Missing site name parameter."
        return 1
    fi

    # Ensure the backup file exists
    if [[ ! -f "$backup_file" ]]; then
        echo "${CROSSMARK} The backup file does not exist: $backup_file"
        return 1
    fi

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

    # Ask for confirmation before dropping the database
    echo -e "\n${WARNING} WARNING: The database will be completely dropped before importing the new data. Are you sure you want to proceed? (y/n)"
    read -rp "Confirm (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "${CROSSMARK} Action canceled. No changes were made."
        return 1
    fi

    # Call the database reset logic to drop all data
    echo "${IMPORTANT}${NC} Dropping existing database: $db_name for site: $domain..."
    bash "$CLI_DIR/database_reset.sh" --domain="$domain"

    # Proceed to restore the database from the backup file
    echo "Restoring database: $db_name for site: $domain from file: $backup_file..."

    # Run the import command inside the container
    if ! docker exec --env MYSQL_PWD="$db_password" ${domain}-mariadb mysql -u$db_user $db_name < "$backup_file"; then
        echo "${CROSSMARK} Failed to import the database '$db_name' in container."
        return 1
    fi

    echo "${CHECKMARK} Database import completed!"
}