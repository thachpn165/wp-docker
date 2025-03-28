#!/bin/bash

# Import required functions from backup-manager
source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/backup_files.sh"
source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/backup_database.sh"
source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/cleanup_backups.sh"
source "$SCRIPTS_FUNCTIONS_DIR/rclone/manage_rclone.sh"

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

    # Ask user where to save backup before proceeding
    echo -e "${BLUE}📂 Select backup storage location:${NC}"
    echo -e "  ${GREEN}[1]${NC} 💾 Save to server (local)"
    echo -e "  ${GREEN}[2]${NC} ☁️  Save to configured Storage"
    read -p "🔹 Select an option (1-2): " storage_choice

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
            read -p "🔹 Enter Storage name to use: " selected_storage
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

    # Start backup process
    echo -e "${YELLOW}🔹 Backing up database and source code...${NC}"
    db_backup_file=$(backup_database "$SITE_NAME" "$DB_NAME" "$DB_USER" "$DB_PASS" | tail -n 1)
    files_backup_file=$(backup_files "$SITE_NAME" "$web_root" | tail -n 1)

    # Check if backup files exist
    if [[ ! -f "$db_backup_file" || ! -f "$files_backup_file" ]]; then
        echo -e "${RED}❌ Error: Could not find backup files!${NC}"
        echo -e "${RED}🛑 Check paths:${NC}"
        echo -e "📂 Database: $db_backup_file"
        echo -e "📂 Files: $files_backup_file"
        return 1
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

# Function to delete old backups
cleanup_old_backups() {
    select_website || return

    read -p "Keep backups for how many days? (e.g., 7): " RETENTION_DAYS
    cleanup_backups "$SITE_NAME" "$RETENTION_DAYS"
}

# Function to list backup files
list_backup_files() {
    select_website || return

    local backup_dir="$SITES_DIR/$SITE_NAME/backups"

    if ! is_directory_exist "$backup_dir"; then
        echo -e "${RED}❌ Backup directory not found in $backup_dir${NC}"
        return 1
    fi

    echo -e "${BLUE}📂 Backup list for $SITE_NAME:${NC}"

    # Determine operating system (macOS or Linux)
    if [[ "$(uname)" == "Darwin" ]]; then
        FIND_CMD="ls -lt $backup_dir | awk '{print \$6, \$7, \$8, \$9}'"
    else
        FIND_CMD="find $backup_dir -type f -printf '%TY-%Tm-%Td %TH:%TM %p\n' | sort -r"
    fi

    # Display database backups
    echo -e "${GREEN}🗄️ Database Backups:${NC}"
    eval "$FIND_CMD" | grep "db-.*\.sql" | awk '{print "  📄 " $1, $2, "-", $NF}'

    # Display source code backups
    echo -e "${YELLOW}📂 Source Code Backups:${NC}"
    eval "$FIND_CMD" | grep "files-.*\.tar.gz" | awk '{print "  📦 " $1, $2, "-", $NF}'
}



