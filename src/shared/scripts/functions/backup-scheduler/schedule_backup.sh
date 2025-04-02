#!/bin/bash

CONFIG_FILE="shared/config/config.sh"

# Determine absolute path of `config.sh`
while [ ! -f "$CONFIG_FILE" ]; do
    CONFIG_FILE="../$CONFIG_FILE"
    if [ "$(pwd)" = "/" ]; then
        echo "❌ Error: config.sh not found!" >&2
        exit 1
    fi
done

source "$CONFIG_FILE"

# Function to schedule backup
schedule_backup_create() {
    select_website || return

    local log_dir="$SITES_DIR/$SITE_NAME/logs"
    local log_file="$log_dir/wp-backup.log"
    local cron_job=""
    local backup_script="$SCRIPTS_FUNCTIONS_DIR/backup-scheduler/backup_runner.sh"

    is_directory_exist "$log_dir"

    # Ask user where to store backup (Local or Storage)
    echo -e "${BLUE}📂 Select backup storage location:${NC}"
    echo -e "  ${GREEN}[1]${NC} 💾 Save to server (local)"
    echo -e "  ${GREEN}[2]${NC} ☁️  Save to configured Storage"
    [[ "$TEST_MODE" != true ]] && read -p "🔹 Select an option (1-2): " storage_choice

    local storage_option="local"
    local selected_storage=""

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
            selected_storage=$(echo "$selected_storage" | xargs)  # Remove extra whitespace

            # Check if storage exists in the list
            if [[ " ${storages[*]} " =~ " ${selected_storage} " ]]; then
                echo -e "${GREEN}☁️  Selected Storage: '$selected_storage'${NC}"
                storage_option="$selected_storage"
                break
            else
                echo -e "${RED}❌ Invalid Storage! Please enter the correct Storage name.${NC}"
            fi
        done
    fi

    echo -e "${BLUE}📅 Select automatic backup schedule:${NC}"
    echo -e "  ${GREEN}[1]${NC} Daily (02:00 AM)"
    echo -e "  ${GREEN}[2]${NC} Weekly (Sunday at 03:00 AM)"
    echo -e "  ${GREEN}[3]${NC} Monthly (Day 1 at 04:00 AM)"
    echo -e "  ${GREEN}[4]${NC} Custom schedule"
    echo -e "  ${GREEN}[5]${NC} Exit"
    echo ""

    [[ "$TEST_MODE" != true ]] && read -p "🔹 Select an option (1-5): " choice

    case "$choice" in
        1) cron_job="0 2 * * * bash $backup_script $SITE_NAME $storage_option >> $log_file 2>&1" ;;
        2) cron_job="0 3 * * 0 bash $backup_script $SITE_NAME $storage_option >> $log_file 2>&1" ;;
        3) cron_job="0 4 1 * * bash $backup_script $SITE_NAME $storage_option >> $log_file 2>&1" ;;
        4) 
            [[ "$TEST_MODE" != true ]] && read -p "🔹 Enter cron schedule (e.g., '30 2 * * *'): " custom_cron
            cron_job="$custom_cron bash $backup_script $SITE_NAME $storage_option >> $log_file 2>&1"
            ;;
        5) 
            echo -e "${GREEN}❌ Exiting backup schedule setup.${NC}"
            return
            ;;
        *) 
            echo -e "${RED}❌ Invalid option!${NC}"
            return
            ;;
    esac

    # Add cron job to crontab
    (crontab -l 2>/dev/null | grep -v "$backup_script $SITE_NAME"; echo "$cron_job") | crontab -

    echo -e "${GREEN}✅ Backup schedule has been set up successfully!${NC}"
}
