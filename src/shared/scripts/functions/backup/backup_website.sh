backup_website_logic() {
    # Kiểm tra xem SITE_NAME đã được gán chưa
    if [[ -z "$SITE_NAME" ]]; then
        echo -e "${RED}❌ Error: SITE_NAME is not set!${NC}"
        return 1
    fi

    local web_root="$SITES_DIR/$SITE_NAME/wordpress"
    local backup_dir="$(realpath "$SITES_DIR/$SITE_NAME/backups")"
    local log_dir="$(realpath "$SITES_DIR/$SITE_NAME/logs")"
    local db_backup_file=""
    local files_backup_file=""
    local site_name="$1"  # Get site name from argument
    local storage="$2"  # Get storage option (local or cloud)
    local rclone_storage="$3"  # Get rclone storage from argument

    is_directory_exist "$backup_dir"
    is_directory_exist "$log_dir"

    # Get database information from the .env file of the selected site
    local env_file="$SITES_DIR/$SITE_NAME/.env"
    local DB_NAME=$(fetch_env_variable "$env_file" "MYSQL_DATABASE")
    local DB_USER=$(fetch_env_variable "$env_file" "MYSQL_USER")
    local DB_PASS=$(fetch_env_variable "$env_file" "MYSQL_PASSWORD")

    # Ensure valid database parameters are extracted
    if [[ -z "$DB_NAME" || -z "$DB_USER" || -z "$DB_PASS" ]]; then
        echo -e "${RED}❌ Missing database information in .env file for site $SITE_NAME.${NC}"
        return 1
    fi

    echo -e "${GREEN}✅ Preparing to backup website: $SITE_NAME${NC}"
    echo -e "📂 Source code: $web_root"
    echo -e "🗄️ Database: $DB_NAME (User: $DB_USER)"

    # Set paths for CLI files
    local backup_files_cli="$CLI_DIR/backup_file.sh"
    local backup_database_cli="$CLI_DIR/backup_database.sh"

    # Call the CLI for database backup
    db_backup_file=$(bash "$backup_database_cli" --site_name="$SITE_NAME" --db_name="$DB_NAME" --db_user="$DB_USER" --db_pass="$DB_PASS" | tail -n 1)

    # Call the CLI for files backup
    files_backup_file=$(bash "$backup_files_cli" --site_name="$SITE_NAME" | tail -n 1)

    # Check if backup files exist
    if [[ ! -f "$db_backup_file" || ! -f "$files_backup_file" ]]; then
        echo -e "${RED}❌ Error: Could not find backup files!${NC}"
        echo -e "${RED}🛑 Check paths:${NC}"
        echo -e "📂 Database: $db_backup_file"
        echo -e "📂 Files: $files_backup_file"
        return 1
    fi

    echo -e "${YELLOW}🔹 Backup completed: Database and files saved.${NC}"

    # Ensure storage is provided and valid
    if [[ "$storage" != "local" && "$storage" != "cloud" ]]; then
        echo -e "${RED}❌ Invalid storage choice! Please use 'local' or 'cloud'.${NC}"
        return 1
    fi

    if [[ "$storage" == "cloud" && -z "$rclone_storage" ]]; then
        echo -e "${RED}❌ rclone storage is required for cloud backup!${NC}"
        return 1
    fi

    if [[ "$storage" == "cloud" ]]; then
        echo -e "${BLUE}📂 Uploading backup to Storage: $rclone_storage${NC}"

        # Check if storage exists in rclone.conf
        if ! grep -q "^\[$rclone_storage\]" "$RCLONE_CONFIG_FILE"; then
            echo -e "${RED}❌ Error: Storage '$rclone_storage' does not exist in rclone.conf!${NC}"
            return 1
        fi

        # Call upload backup to the specified rclone storage
        bash "$SCRIPTS_FUNCTIONS_DIR/rclone/upload_backup.sh" "$rclone_storage" "$db_backup_file" "$files_backup_file"

        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}✅ Backup and upload to Storage completed!${NC}"
            
            # Delete backup files after successful upload
            echo -e "${YELLOW}🗑️ Deleting backup files after successful upload...${NC}"
            rm -f "$db_backup_file" "$files_backup_file"

            # Check if files were deleted
            if [[ ! -f "$db_backup_file" && ! -f "$files_backup_file" ]]; then
                echo -e "${GREEN}✅ Backup files have been deleted from backups directory.${NC}"
            else
                echo -e "${RED}❌ Error: Could not delete backup files!${NC}"
            fi
        else
            echo -e "${RED}❌ Error uploading backup to Storage!${NC}"
        fi
    elif [[ "$storage" == "local" ]]; then
        echo -e "${GREEN}💾 Backup completed and saved to: $backup_dir${NC}"
    fi
}