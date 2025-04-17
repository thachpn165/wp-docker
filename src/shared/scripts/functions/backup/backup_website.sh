# ============================================
# 📅 backup_prompt_create_schedule – Schedule automatic backups using cron
# ============================================
# Description:
#   - Allows the user to select a website, choose a schedule (cron format), 
#     and specify local or cloud storage for automated backups.
#   - Configures a cron job that will trigger the backup with selected settings.
#
# Globals:
#   SITES_DIR, CLI_DIR, RCLONE_CONFIG_FILE
#   INFO_SELECT_BACKUP_SCHEDULE, PROMPT_SELECT_OPTION, PROMPT_ENTER_CUSTOM_CRON
#   INFO_SELECT_STORAGE_LOCATION, LABEL_BACKUP_LOCAL, LABEL_BACKUP_CLOUD
#   PROMPT_SELECT_STORAGE_OPTION, INFO_RCLONE_READING_STORAGE_LIST
#   LABEL_MENU_RCLONE_AVAILABLE_STORAGE, PROMPT_ENTER_STORAGE_NAME
#   ERROR_SELECT_OPTION_INVALID, SUCCESS_CRON_JOB_CREATED, TITLE_CRON_SUMMARY
#   LABEL_CRON_DOMAIN, LABEL_CRON_SCHEDULE, LABEL_CRON_STORAGE, LABEL_CRON_LOG
#   LABEL_CRON_LINE
#
# Parameters:
#   None
#
# Returns:
#   - Creates a cron job entry
# ============================================
backup_prompt_create_schedule() {
    local domain 
    website_get_selected domain
    if [[ -z "$domain" ]]; then
        print_msg error "$ERROR_SITE_NOT_SELECTED"
        exit 1
    fi

    # === Choose schedule time (Cron format) ===
    print_msg info "$INFO_SELECT_BACKUP_SCHEDULE"
    echo "1. $LABEL_CRON_EVERY_DAY_3AM"
    echo "2. $LABEL_CRON_EVERY_SUNDAY_2AM"
    echo "3. $LABEL_CRON_EVERY_MONDAY_1AM"
    echo "4. $LABEL_CUSTOM_SCHEDULE"

    schedule_choice=$(get_input_or_test_value "$PROMPT_SELECT_OPTION" "${TEST_SCHEDULE_CHOICE:-1}")
    case "$schedule_choice" in
    1) schedule_time="0 3 * * *" ;;
    2) schedule_time="0 2 * * 0" ;;
    3) schedule_time="0 1 * * 1" ;;
    4)
        schedule_time=$(get_input_or_test_value "$PROMPT_ENTER_CUSTOM_CRON" "${TEST_CUSTOM_CRON:-0 3 * * *}")
        ;;
    *)
        print_msg warning "$WARNING_INPUT_INVALID"
        exit 1
        ;;
    esac

    # === Choose storage for backup ===
    print_msg info "$INFO_SELECT_STORAGE_LOCATION"
    echo "1. $LABEL_BACKUP_LOCAL"
    echo "2. $LABEL_BACKUP_CLOUD"
    storage_choice=$(get_input_or_test_value "$PROMPT_SELECT_STORAGE_OPTION" "${TEST_STORAGE_CHOICE:-1}")

    local storage="local"
    local rclone_storage=""

    if [[ "$storage_choice" == "2" ]]; then
        print_msg info "$INFO_RCLONE_READING_STORAGE_LIST"
        mapfile -t storages < <(rclone_storage_list)

        if [[ ${#storages[@]} -eq 0 ]]; then
            print_msg error "$WARNING_RCLONE_NO_STORAGE_CONFIGURED"
            exit 1
        fi

        print_msg label "$LABEL_MENU_RCLONE_AVAILABLE_STORAGE:"
        for i in "${!storages[@]}"; do
            echo "  [$i] ${storages[$i]}"
        done

        storage_index=$(get_input_or_test_value "$PROMPT_ENTER_STORAGE_NAME" "${TEST_STORAGE_INDEX:-0}")
        rclone_storage="${storages[$storage_index]}"

        if [[ -z "$rclone_storage" ]]; then
            print_msg error "$ERROR_SELECT_OPTION_INVALID"
            exit 1
        fi

        storage="cloud"
    fi

    # === Set log file path ===
    local backup_log_file="$SITES_DIR/$domain/logs/backup_schedule.logs"

    # === Compose command for cron job ===
    local backup_command="bash $CLI_DIR/backup_website.sh --domain=$domain --storage=$storage"
    [[ "$storage" == "cloud" ]] && backup_command+=" --rclone_storage=$rclone_storage"

    # Add to crontab
    (
        crontab -l 2>/dev/null
        echo "$schedule_time $backup_command >> $backup_log_file 2>&1"
    ) | crontab -

    local readable_schedule
    readable_schedule=$(cron_translate "$schedule_time")

    print_msg success "$SUCCESS_CRON_JOB_CREATED"
    echo -e "${CYAN}📅 $TITLE_CRON_SUMMARY${NC}"
    echo ""
    echo -e "${GREEN}$LABEL_CRON_DOMAIN    :${NC} $domain"
    echo -e "${GREEN}$LABEL_CRON_SCHEDULE  :${NC} $readable_schedule"
    echo -e "${GREEN}$LABEL_CRON_STORAGE   :${NC} $storage${rclone_storage:+ → $rclone_storage}"
    echo -e "${GREEN}$LABEL_CRON_LOG       :${NC} $backup_log_file"
    echo -e "${GREEN}$LABEL_CRON_LINE      :${NC} $schedule_time $backup_command"
    echo
}

# ============================================
# 💾 backup_prompt_backup_web – Trigger manual website backup
# ============================================
# Description:
#   - Prompts the user to select a website and backup destination (local/cloud).
#   - If cloud is selected, prompts for a specific rclone storage.
#   - Triggers `backup_logic_website` with selected options.
#
# Globals:
#   SITES_DIR, RCLONE_CONFIG_FILE
#   ERROR_NO_WEBSITE_SELECTED, PROMPT_BACKUP_CHOOSE_STORAGE
#   LABEL_MENU_RCLONE_AVAILABLE_STORAGE, WARNING_RCLONE_NO_STORAGE_CONFIGURED
#   ERROR_SELECT_OPTION_INVALID, SUCCESS_RCLONE_STORAGE_SELECTED
#
# Parameters:
#   None
#
# Returns:
#   - Invokes backup process via `backup_logic_website`
# ============================================
backup_prompt_backup_web() {
    local domain 
    website_get_selected domain

    if [[ -z "$domain" ]]; then
        print_msg error "$ERROR_NO_WEBSITE_SELECTED"
        exit 1
    fi

    # === Choose storage: local or cloud ===
    print_msg info "$PROMPT_BACKUP_CHOOSE_STORAGE"
    select storage_choice in "local" "cloud"; do
        case $storage_choice in
        local)
            storage="local"
            break
            ;;
        cloud)
            storage="cloud"
            break
            ;;
        *)
            print_msg error "$ERROR_INVALID_CHOICE: $storage_choice"
            ;;
        esac
    done

    # === If cloud storage is selected, ask for rclone storage selection ===
    if [[ "$storage" == "cloud" ]]; then

        # Get list of storage names from rclone.conf, removing brackets
        mapfile -t rclone_storages < <(grep -o '^\[.*\]' "$RCLONE_CONFIG_FILE" | sed 's/\[\(.*\)\]/\1/g')

        # Check if there are storages available
        if [[ ${#rclone_storages[@]} -eq 0 ]]; then
            print_msg error "$WARNING_RCLONE_NO_STORAGE_CONFIGURED"
            exit 1
        fi

        # Display list of available rclone storages
        print_msg label "$LABEL_MENU_RCLONE_AVAILABLE_STORAGE"
        for i in "${!rclone_storages[@]}"; do
            echo "[$i] ${rclone_storages[$i]}"
        done

        # Prompt the user to select a storage
        read -p "Select storage (number): " selected_storage_index

        if [[ -z "${rclone_storages[$selected_storage_index]}" ]]; then
            print_msg error "$ERROR_SELECT_OPTION_INVALID: $selected_storage_index"
            exit 1
        fi

        selected_storage="${rclone_storages[$selected_storage_index]}"
        print_msg error "$SUCCESS_RCLONE_STORAGE_SELECTED: $selected_storage"
    fi

    # === Pass selected parameters to the backup logic ===
    backup_logic_website "$domain" "$storage" "$selected_storage"

}

# ============================================
# 🛠 backup_logic_website – Execute the backup process for a website
# ============================================
# Description:
#   - Performs database and file backup for a specific website.
#   - Supports uploading to cloud storage via rclone if selected.
#   - Deletes local backup files after successful cloud upload.
#
# Parameters:
#   $1 - domain (required)
#   $2 - storage type: "local" or "cloud" (required)
#   $3 - rclone_storage (required if cloud storage is used)
#
# Globals:
#   CLI_DIR, SITES_DIR, SCRIPTS_FUNCTIONS_DIR, RCLONE_CONFIG_FILE
#   ERROR_MISSING_PARAM, STEP_BACKUP_START, MSG_WEBSITE_BACKING_UP_DB
#   MSG_WEBSITE_BACKING_UP_FILES, ERROR_BACKUP_FILE_NOT_FOUND
#   INFO_BACKUP_COMPLETED, ERROR_INVALID_STORAGE_CHOICE
#   ERROR_RCLONE_STORAGE_REQUIRED, INFO_RCLONE_UPLOAD_START
#   ERROR_STORAGE_NOT_EXIST, MSG_BACKUP_UPLOAD_DONE, MSG_BACKUP_DELETE_LOCAL
#   SUCCESS_BACKUP_FILES_DELETED, ERROR_BACKUP_DELETE_FAILED
#   ERROR_BACKUP_UPLOAD_FAILED, SUCCESS_BACKUP_LOCAL_SAVED
#
# Returns:
#   - 0 on success, 1 on failure
# ============================================
backup_logic_website() {

    # Define backup and log directories
    local domain="$1"
    local storage="$2"
    local rclone_storage="$3"
    local db_backup_file
    local files_backup_file
    local backup_dir

    local log_dir
    local log_file
    log_file="$log_dir/wp-backup.log"
    safe_source "$CLI_DIR/backup_website.sh"
    safe_source "$CLI_DIR/database_actions.sh"
    # Kiểm tra nếu domain hoặc storage không có giá trị, thoát hàm ngay lập tức
    if [[ -z "$domain" || -z "$storage" ]]; then
        print_and_debug error "$ERROR_MISSING_PARAM: --domain and --storage must be provided"
        return 1
    fi

    backup_dir="$(realpath "$SITES_DIR/$domain/backups")"
    log_dir="$(realpath "$SITES_DIR/$domain/logs")"

    # Ensure backup and logs directories exist
    is_directory_exist "$backup_dir"
    is_directory_exist "$log_dir"

    # Log start of backup process
    print_msg step "$STEP_BACKUP_START: $domain"
    debug_log "[backup_logic_website] Backup dir: $backup_dir"
    debug_log "[backup_logic_website] Log file: $log_file"

    # Backup database using the existing database_export_logic
    print_msg info "$MSG_WEBSITE_BACKING_UP_DB"
    db_backup_file=$(database_cli_export --domain="$domain" | tail -n 1)
    debug_log "[backup_logic_website] DB backup file: $db_backup_file"

    print_msg info "$MSG_WEBSITE_BACKING_UP_FILES"
    files_backup_file=$(backup_cli_file --domain="$domain" | tail -n 1)
    debug_log "[backup_logic_website] Files backup file: $files_backup_file"

    # Check if backup files exist
    if [[ ! -f "$db_backup_file" || ! -f "$files_backup_file" ]]; then
        print_and_debug error "$ERROR_BACKUP_FILE_NOT_FOUND"
        return 1
    fi

    print_msg success "$INFO_BACKUP_COMPLETED : $domain"

    # Ensure valid storage option
    if [[ "$storage" != "local" && "$storage" != "cloud" ]]; then
        print_and_debug error "$ERROR_INVALID_STORAGE_CHOICE"
        return 1
    fi

    if [[ "$storage" == "cloud" && -z "$rclone_storage" ]]; then
        print_and_debug error "$ERROR_RCLONE_STORAGE_REQUIRED"
        return 1
    fi

    if [[ "$storage" == "cloud" ]]; then
        formatted_msg="$(printf "$INFO_RCLONE_UPLOAD_START" "$rclone_storage")"
        print_msg info "$formatted_msg"

        # Check if storage exists in rclone.conf
        if ! grep -q "^\[$rclone_storage\]" "$RCLONE_CONFIG_FILE"; then
            print_and_debug error "$ERROR_STORAGE_NOT_EXIST"
            return 1
        fi

        # Call upload backup to the specified rclone storage
        bash "$SCRIPTS_FUNCTIONS_DIR/rclone/upload_backup.sh" "$rclone_storage" "$db_backup_file" "$files_backup_file"

        if [[ $? -eq 0 ]]; then
            print_msg step "$MSG_BACKUP_UPLOAD_DONE : $rclone_storage"
            debug_log "[backup_logic_website] Backup files uploaded to $rclone_storage"

            # Delete backup files after successful upload
            print_msg step "$MSG_BACKUP_DELETE_LOCAL"
            rm -f "$db_backup_file" "$files_backup_file"

            # Check if files were deleted
            if [[ ! -f "$db_backup_file" && ! -f "$files_backup_file" ]]; then
                print_msg success "$SUCCESS_BACKUP_FILES_DELETED"
            else
                print_and_debug error "$ERROR_BACKUP_DELETE_FAILED"
            fi
        else
            print_and_debug error "$ERROR_BACKUP_UPLOAD_FAILED"
        fi
    elif [[ "$storage" == "local" ]]; then
        formatted_msg="$(printf "$SUCCESS_BACKUP_LOCAL_SAVED" "$backup_dir")"
        print_msg success "$formatted_msg"
    fi
}
