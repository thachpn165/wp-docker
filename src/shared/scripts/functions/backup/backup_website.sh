#!/bin/bash
# ==================================================
# File: backup_website.sh
# Description: Functions to manage website backups, including scheduling automatic backups, 
#              triggering manual backups, and executing the backup process for a website.
# Functions:
#   - backup_prompt_create_schedule: Schedule automatic backups for a website.
#       Parameters: None.
#   - backup_prompt_backup_web: Trigger manual website backup.
#       Parameters: None.
#   - backup_logic_create_schedule: Create a backup schedule for a website.
#       Parameters:
#           $1 - domain: The domain name of the website.
#           $2 - interval_days: The interval in days for the backup schedule.
#           $3 - storage: The storage type ("local" or "cloud").
#           $4 - rclone_storage (optional): The rclone storage name for cloud backups.
#   - backup_logic_website: Execute the backup process for a website.
#       Parameters:
#           $1 - domain: The domain name of the website.
#           $2 - storage: The storage type ("local" or "cloud").
#           $3 - rclone_storage (optional): The rclone storage name for cloud backups.
# ==================================================

backup_prompt_create_schedule() {
    local domain
    if ! website_get_selected domain; then
        return 1
    fi
    _is_valid_domain "$domain" || exit 1

    # Prompt for interval_days
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

    # Choose storage for backup
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

    # Save schedule to config
    backup_logic_create_schedule "$domain" "$interval_days" "$storage" "$rclone_storage"

    print_msg success "$SUCCESS_CRON_JOB_CREATED"
    echo -e "${CYAN}📅 $TITLE_CRON_SUMMARY${NC}"
    echo
    echo -e "${GREEN}$LABEL_CRON_DOMAIN    :${NC} $domain"
    echo -e "${GREEN}$LABEL_CRON_INTERVAL  :${NC} $interval_days $LABEL_DAYS_LOWERCASE"
    echo -e "${GREEN}$LABEL_CRON_STORAGE   :${NC} $storage${rclone_storage:+ → $rclone_storage}"
    echo
}

backup_prompt_backup_web() {
    local domain

    if ! website_get_selected domain; then
        return 1
    fi
    _is_valid_domain "$domain" || exit 1

    # Choose storage: local or cloud
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

    # If cloud storage is selected, ask for rclone storage selection
    if [[ "$storage" == "cloud" ]]; then
        mapfile -t rclone_storages < <(grep -o '^\[.*\]' "$RCLONE_CONFIG_FILE" | sed 's/\[\(.*\)\]/\1/g')

        if [[ ${#rclone_storages[@]} -eq 0 ]]; then
            print_msg error "$WARNING_RCLONE_NO_STORAGE_CONFIGURED"
            exit 1
        fi

        print_msg label "$LABEL_MENU_RCLONE_AVAILABLE_STORAGE"
        for i in "${!rclone_storages[@]}"; do
            echo "[$i] ${rclone_storages[$i]}"
        done

        read -p "Select storage (number): " selected_storage_index

        if [[ -z "${rclone_storages[$selected_storage_index]}" ]]; then
            print_msg error "$ERROR_SELECT_OPTION_INVALID: $selected_storage_index"
            exit 1
        fi

        selected_storage="${rclone_storages[$selected_storage_index]}"
        print_msg error "$SUCCESS_RCLONE_STORAGE_SELECTED: $selected_storage"
    fi

    # Pass selected parameters to the backup logic
    backup_logic_website "$domain" "$storage" "$selected_storage"
}

backup_logic_create_schedule() {
    local domain="$1"
    local interval_days="$2"
    local storage="$3"
    local rclone_storage="$4"

    if ! [[ "$interval_days" =~ ^[0-9]+$ ]] || [[ "$interval_days" -lt 1 ]]; then
        print_and_debug error "[backup_logic_create_schedule] Invalid interval_days: $interval_days"
        return 1
    fi
    _is_valid_domain "$domain" || return 1
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

backup_logic_website() {
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
    _is_valid_domain "$domain" || return 1
    backup_dir="$(realpath "$SITES_DIR/$domain/backups")"
    log_dir="$(realpath "$SITES_DIR/$domain/logs")"

    _is_directory_exist "$backup_dir"
    _is_directory_exist "$log_dir"

    print_msg step "$STEP_BACKUP_START: $domain"
    debug_log "[backup_logic_website] Backup dir: $backup_dir"
    debug_log "[backup_logic_website] Log file: $log_file"

    print_msg info "$MSG_WEBSITE_BACKING_UP_DB"
    db_backup_file=$(database_cli_export --domain="$domain" | tail -n 1)
    debug_log "[backup_logic_website] DB backup file: $db_backup_file"

    print_msg info "$MSG_WEBSITE_BACKING_UP_FILES"
    files_backup_file=$(backup_cli_file --domain="$domain" | tail -n 1)
    debug_log "[backup_logic_website] Files backup file: $files_backup_file"

    if [[ ! -f "$db_backup_file" || ! -f "$files_backup_file" ]]; then
        print_and_debug error "$ERROR_BACKUP_FILE_NOT_FOUND"
        return 1
    fi

    print_msg success "$INFO_BACKUP_COMPLETED : $domain"

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

        if ! grep -q "^\[$rclone_storage\]" "$RCLONE_CONFIG_FILE"; then
            print_and_debug error "$ERROR_STORAGE_NOT_EXIST"
            return 1
        fi

        bash "$SCRIPTS_FUNCTIONS_DIR/rclone/upload_backup.sh" "$rclone_storage" "$db_backup_file" "$files_backup_file"

        if [[ $? -eq 0 ]]; then
            print_msg step "$MSG_BACKUP_UPLOAD_DONE : $rclone_storage"
            debug_log "[backup_logic_website] Backup files uploaded to $rclone_storage"

            print_msg step "$MSG_BACKUP_DELETE_LOCAL"
            rm -f "$db_backup_file" "$files_backup_file"

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