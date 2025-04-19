# ============================================
# 📅 backup_prompt_create_schedule – Schedule automatic backups per site
# ============================================
# Description:
#   - Allows the user to select a website, choose a backup interval (in days),
#     and specify local or cloud storage for automated backups.
#   - Saves the configuration to .config.json under `.site[domain].backup_schedule`
#   - This information will be used by cron_loader.sh to run backups accordingly.
#
# Globals:
#   SITES_DIR, BASE_DIR
#   INFO_SELECT_BACKUP_SCHEDULE, PROMPT_SELECT_OPTION, PROMPT_ENTER_CUSTOM_INTERVAL_DAYS
#   LABEL_CUSTOM_INTERVAL, LABEL_DAY_LOWERCASE, LABEL_DAYS_LOWERCASE
#   INFO_SELECT_STORAGE_LOCATION, LABEL_BACKUP_LOCAL, LABEL_BACKUP_CLOUD
#   PROMPT_SELECT_STORAGE_OPTION, INFO_RCLONE_READING_STORAGE_LIST
#   LABEL_MENU_RCLONE_AVAILABLE_STORAGE, PROMPT_ENTER_STORAGE_NAME
#   ERROR_SELECT_OPTION_INVALID, SUCCESS_CRON_JOB_CREATED, TITLE_CRON_SUMMARY
#   LABEL_CRON_DOMAIN, LABEL_CRON_INTERVAL, LABEL_CRON_STORAGE
#
# Parameters:
#   None
#
# Returns:
#   - Saves backup_schedule block into .config.json for the selected domain
#   - Displays a summary of the saved schedule
# ============================================
backup_prompt_create_schedule() {
    local domain
    website_get_selected domain
    if [[ -z "$domain" ]]; then
        print_msg error "$ERROR_SITE_NOT_SELECTED"
        exit 1
    fi

    # === Prompt for interval_days ===
    print_msg info "$INFO_SELECT_BACKUP_SCHEDULE"
    echo "1. 1 $LABEL_DAY_LOWERCASE"
    echo "2. 3 $LABEL_DAYS_LOWERCASE"
    echo "3. 7 $LABEL_DAYS_LOWERCASE"
    echo "4. $LABEL_CUSTOM_INTERVAL"

    local interval_days
    schedule_choice=$(get_input_or_test_value "$PROMPT_SELECT_OPTION" "${TEST_SCHEDULE_CHOICE:-1}")
    case "$schedule_choice" in
    1) interval_days=1 ;;
    2) interval_days=3 ;;
    3) interval_days=7 ;;
    4)
        interval_days=$(get_input_or_test_value "$PROMPT_ENTER_CUSTOM_INTERVAL_DAYS" "${TEST_CUSTOM_INTERVAL_DAYS:-1}")
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

    # === Save schedule to config ===
    backup_logic_create_schedule "$domain" "$interval_days" "$storage" "$rclone_storage"

    print_msg success "$SUCCESS_CRON_JOB_CREATED"
    echo -e "${CYAN}📅 $TITLE_CRON_SUMMARY${NC}"
    echo
    echo -e "${GREEN}$LABEL_CRON_DOMAIN    :${NC} $domain"
    echo -e "${GREEN}$LABEL_CRON_INTERVAL  :${NC} $interval_days $LABEL_DAYS_LOWERCASE"
    echo -e "${GREEN}$LABEL_CRON_STORAGE   :${NC} $storage${rclone_storage:+ → $rclone_storage}"
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

backup_logic_create_schedule() {
    local domain="$1"
    local interval_days="$2"
    local storage="$3"
    local rclone_storage="$4"

    if [[ -z "$domain" || -z "$interval_days" || -z "$storage" ]]; then
        print_and_debug error "[backup_logic_create_schedule] Missing required parameters"
        return 1
    fi

    if ! [[ "$interval_days" =~ ^[0-9]+$ ]] || [[ "$interval_days" -lt 1 ]]; then
        print_and_debug error "[backup_logic_create_schedule] Invalid interval_days: $interval_days"
        return 1
    fi

    # Ghi từng key một bằng json_set_site_value
    json_set_site_value "$domain" "backup_schedule.enabled" "true"
    json_set_site_value "$domain" "backup_schedule.interval_days" "$interval_days"
    json_set_site_value "$domain" "backup_schedule.storage" "$storage"

    if [[ "$storage" == "cloud" && -n "$rclone_storage" ]]; then
        json_set_site_value "$domain" "backup_schedule.rclone_storage" "$rclone_storage"
    else
        json_delete_site_field "$domain" "backup_schedule.rclone_storage"
    fi

    debug_log "[backup_logic_create_schedule] Created schedule for $domain: every $interval_days day(s), storage=$storage"
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
