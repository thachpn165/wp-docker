#shellcheck disable=SC1091
#shellcheck disable=SC2162
backup_prompt_backup_manage() {
    safe_source "$CLI_DIR/backup_manage.sh"
    select_website
    if [[ -z "$domain" ]]; then
        print_and_debug "$ERROR_MISSING_PARAM: --domain must be provided"
        exit 1
    fi

    print_msg info "$MSG_WEBSITE_SELECTED: $domain"

    # === Choose action: list or clean ===
    print_msg label "$PROMPT_ENTER_ACTION_NUMBER"
    select action_choice in "list" "clean"; do
        case $action_choice in
        list)
            echo ""
            action="list"
            break
            ;;
        clean)
            echo ""
            action="clean"
            break
            ;;
        *)
            print_and_debug error "$ERROR_INVALID_CHOICE: $action_choice"
            ;;
        esac
    done

    backup_cli_manage --domain="$domain" --action="$action"
}

backup_logic_manage() {
    local domain="$1"
    local backup_dir="$SITES_DIR/$domain/backups"
    local action="$2"
    local max_age_days="${3}"
    local formatted_msg_cleaning_old_backups

    # Check if the backup directory exists
    if $(is_directory_exist "$backup_dir"); then
        print_and_debug error "$(printf "$ERROR_DIRECTORY_NOT_FOUND" "$backup_dir")"
        mkdir -p "$backup_dir"
        return 1
    fi
    case "$action" in
    "list")
        print_msg step "$MSG_BACKUP_LISTING: $domain"

        if [[ "$(uname)" == "Darwin" ]]; then
            print_msg label "$LABEL_BACKUP_FILE_LIST"
            ls -lt "$backup_dir" | awk '{print $6, $7, $8, $9}' | grep ".tar.gz"

            print_msg label "$LABEL_BACKUP_DB_LIST"
            ls -lt "$backup_dir" | awk '{print $6, $7, $8, $9}' | grep ".sql"
        else
            print_msg label "$LABEL_BACKUP_FILE_LIST"
            find "$backup_dir" -type f -printf '%TY-%Tm-%Td %TH:%TM %p\n' | sort -r | grep ".tar.gz"

            print_msg label "$LABEL_BACKUP_DB_LIST"
            find "$backup_dir" -type f -printf '%TY-%Tm-%Td %TH:%TM %p\n' | sort -r | grep ".sql"
        fi
        return 0
        ;;
    "clean")

        max_age_days="$(get_input_or_test_value "$PROMPT_BACKUP_MAX_AGE " "${TEST_MAX_AGE_DAYS:-7}")"
        formatted_msg_set_max_age_days=$(printf "$STEP_SET_MAX_AGE_DAYS" "$max_age_days")
        print_msg success "$formatted_msg_set_max_age_days"
        formatted_msg_cleaning_old_backups=$(printf "$STEP_CLEANING_OLD_BACKUPS" "$max_age_days" "$backup_dir")
        print_msg step "$formatted_msg_cleaning_old_backups"
        if [[ "$DEBUG_MODE" == true ]]; then
            local old_files_count
            old_files_count=$(find "$backup_dir" -type f \( -name "*.tar.gz" -o -name "*.sql" \) -mtime +$max_age_days | wc -l)
            debug_log "Found $old_files_count old backup files to delete (older than $max_age_days days)"
        fi
        find "$backup_dir" -type f -name "*.tar.gz" -mtime +$max_age_days -exec rm -f {} \;
        print_msg success "$SUCCESS_BACKUP_CLEAN"
        return 0
        ;;
    *)
        print_and_debug error "$ERROR_BACKUP_INVALID_ACTION"
        debug_log "Invalid action: $action"
        return 1
        ;;
    esac
}
