# database_export_logic – Logic to export database (backup)

database_export_logic() {
    local site_name="$1"
    local save_location="$2"  # Đã được truyền từ file cli

    # Ensure PROJECT_DIR is set
    if [[ -z "$SITES_DIR" ]]; then
        echo -e "${CROSSMARK} SITES_DIR is not set. Ensure config.sh is sourced correctly."
        return 1
    fi

    # Ensure $site_name is set
    if [[ -z "$site_name" ]]; then
        echo -e "${CROSSMARK} Missing site name parameter."
        return 1
    fi

    # Ensure the backup directory exists
    local backup_dir=$(dirname "$save_location")
    if [[ ! -d "$backup_dir" ]]; then
        echo -e "${CROSSMARK} Backup directory does not exist. Creating directory: $backup_dir"
        mkdir -p "$backup_dir" || { echo -e "${CROSSMARK} Failed to create backup directory."; return 1; }
    fi

    # Fetch database credentials from the website's .env file
    local db_info
    db_info=$(db_fetch_env "$site_name")
    
    # Check if fetching database credentials was successful
    if [[ $? -ne 0 ]]; then
        echo -e "${CROSSMARK} Failed to fetch database credentials for site '$site_name'."
        return 1
    fi

    # Parse the database credentials
    local db_name db_user db_password
    IFS=' ' read -r db_name db_user db_password <<< "$db_info"

    # Check if MariaDB container is running
    if ! is_mariadb_running "$site_name"; then
        echo -e "${CROSSMARK} MariaDB container for site '$site_name' is not running. Please check!"
        return 1
    fi

    # Proceed to backup the database
    echo -e "${SAVE} Backing up database: $db_name for site: $site_name..."

    # Run mysqldump inside the container with the --env flag to securely pass the password
    # Export the backup file directly into the save_location on the host
    if ! docker exec --env MYSQL_PWD="$db_password" ${site_name}-mariadb mysqldump -u$db_user $db_name > "$save_location"; then
        echo -e "${CROSSMARK} Failed to backup the database '$db_name' in container."
        return 1
    fi

    echo -e "${CHECKMARK} Backup completed successfully"

    # Get file details: name, creation time, and size in MB
    file_name=$(basename "$save_location")
    file_size=$(du -sh "$save_location" | cut -f1)

    # Check if we are on macOS or Linux to use the appropriate stat command
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS stat
        file_time=$(stat -f %SB -t "%Y-%m-%d %H:%M:%S" "$save_location")
    else
        # Linux stat
        file_time=$(stat -c %y "$save_location")
    fi
    echo -e ""
    echo -e "${GREEN}File Name:${NC} $file_name"
    echo -e "${GREEN}File Size:${NC} $file_size"
    echo -e "${GREEN}File Creation Time:${NC} $file_time"
    echo -e "${GREEN}Backup file saved at:${NC} $save_location"

    # Return the path of the backup file
    echo "$save_location"
}