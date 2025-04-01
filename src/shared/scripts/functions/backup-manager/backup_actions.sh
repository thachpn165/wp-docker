#!/bin/bash
backup_website() {
    select_website || return

    local env_file="$SITES_DIR/$SITE_NAME/.env"
    local web_root="$SITES_DIR/$SITE_NAME/wordpress"
    local backup_dir="$(realpath "$SITES_DIR/$SITE_NAME/backups")"
    local log_dir="$(realpath "$SITES_DIR/$SITE_NAME/logs")"
    local db_backup_file=""
    local files_backup_file=""
    local storage_choice=""
    local selected_storage=""

    is_directory_exist "$backup_dir"
    is_directory_exist "$log_dir"

    if [[ ! -f "$env_file" ]]; then
        echo -e "${RED}❌ .env file not found in $SITES_DIR/$SITE_NAME!${NC}"
        return 1
    fi

    # Get database information from .env
    DB_NAME=$(grep "^MYSQL_DATABASE=" "$env_file" | cut -d '=' -f2)
    DB_USER=$(grep "^MYSQL_USER=" "$env_file" | cut -d '=' -f2)
    DB_PASS=$(grep "^MYSQL_PASSWORD=" "$env_file" | cut -d '=' -f2)

    if [[ -z "$DB_NAME" || -z "$DB_USER" || -z "$DB_PASS" ]]; then
        echo -e "${RED}❌ Error: Could not get database information from .env!${NC}"
        return 1
    fi

    echo -e "${GREEN}✅ Preparing to backup website: $SITE_NAME${NC}"
    echo -e "📂 Source code: $web_root"
    echo -e "🗄️ Database: $DB_NAME (User: $DB_USER)"

    # Set paths for CLI files
    local backup_files_cli="$CLI_DIR/backup/backup_file.sh"
    local backup_database_cli="$CLI_DIR/backup/backup_database.sh"

    # Call the CLI for database backup
    db_backup_file=$(bash "$backup_database_cli" --site_name="$SITE_NAME" --db_name="$DB_NAME" --db_user="$DB_USER" --db_pass="$DB_PASS" | tail -n 1)

    # Call the CLI for files backup
    files_backup_file=$(bash "$backup_files_cli" --site_name="$SITE_NAME" --webroot="$web_root" | tail -n 1)

    # Check if backup files exist
    if [[ ! -f "$db_backup_file" || ! -f "$files_backup_file" ]]; then
        echo -e "${RED}❌ Error: Could not find backup files!${NC}"
        echo -e "${RED}🛑 Check paths:${NC}"
        echo -e "📂 Database: $db_backup_file"
        echo -e "📂 Files: $files_backup_file"
        return 1
    fi

    echo -e "${YELLOW}🔹 Backup completed: Database and files saved.${NC}"

    # Ask user where to save backup before proceeding
    echo -e "${BLUE}📂 Select backup storage location:${NC}"
    echo -e "  ${GREEN}[1]${NC} 💾 Save to server (local)"
    echo -e "  ${GREEN}[2]${NC} ☁️  Save to configured Storage"
    [[ "$TEST_MODE" != true ]] && read -p "🔹 Select an option (1-2): " storage_choice

    if [[ "$storage_choice" == "2" ]]; then
        echo -e "${BLUE}📂 Getting Storage list from rclone.conf...${NC}"

        # Call `rclone_storage_list()` to get Storage list
        local storages=()
        while IFS= read -r line; do
            storages+=("$line")
        done < <(rclone_storage_list)

        if [[ ${#storages[@]} -eq 0 ]]; then
            echo -e "${RED}❌ No Storage configured in rclone.conf!${NC}"
            return 1
        fi

        # Display Storage list clearly
        echo -e "${BLUE}📂 Available Storage list:${NC}"
        for storage in "${storages[@]}"; do
            echo -e "  ${GREEN}➜${NC} ${CYAN}$storage${NC}"
        done

        echo -e "${YELLOW}💡 Please enter the exact Storage name from the list above.${NC}"
        while true; do
            [[ "$TEST_MODE" != true ]] && read -p "🔹 Enter Storage name to use: " selected_storage
            selected_storage=$(echo "$selected_storage" | xargs)  # Remove extra spaces

            # Check if storage exists in list
            if [[ " ${storages[*]} " =~ " ${selected_storage} " ]]; then
                echo -e "${GREEN}☁️  Selected Storage: '$selected_storage'${NC}"
                break
            else
                echo -e "${RED}❌ Invalid Storage! Please enter the correct Storage name.${NC}"
            fi
        done
    fi

    if [[ "$storage_choice" == "1" ]]; then
        echo -e "${GREEN}💾 Backup completed and saved to: $backup_dir${NC}"
    elif [[ "$storage_choice" == "2" ]]; then
        echo -e "${GREEN}☁️  Saving backup to Storage: '$selected_storage'${NC}"

        # Check if storage exists in rclone.conf
        if ! grep -q "^\[$selected_storage\]" "$RCLONE_CONFIG_FILE"; then
            echo -e "${RED}❌ Error: Storage '$selected_storage' does not exist in rclone.conf!${NC}"
            return 1
        fi

        # Call upload backup
        bash "$SCRIPTS_FUNCTIONS_DIR/rclone/upload_backup.sh" "$selected_storage" "$db_backup_file" "$files_backup_file"

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
    fi
}
