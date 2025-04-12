#shellcheck disable=SC1091
#shellcheck disable=SC2162
backup_prompt_backup_manage() {
    safe_source "$CLI_DIR/backup_manage.sh"
    select_website
    if [[ -z "$domain" ]]; then
        echo "${CROSSMARK} No website selected. Exiting."
        exit 1
    fi

    echo "Selected site: $domain"

    # === Choose action: list or clean ===
    echo -e "${YELLOW}📂 Choose action:${NC}"
    select action_choice in "list" "clean"; do
        case $action_choice in
        list)
            echo "You selected to list backups."
            action="list"
            break
            ;;
        clean)
            echo "You selected to clean old backups."
            action="clean"
            break
            ;;
        *)
            echo "${CROSSMARK} Invalid option. Please select either 'list' or 'clean'."
            ;;
        esac
    done

    # === If cleaning, ask for max age days ===
    #if [[ "$action" == "clean" ]]; then
    #    max_age_days="$(get_input_or_test_value "Enter the number of days to keep backups: " "${TEST_MAX_AGE_DAYS:-7}")"
    #    echo "You selected to keep backups for $max_age_days days."
    #fi

    backup_cli_manage --domain="$domain" --action="$action"
}

backup_logic_manage() {
    local domain="$1"
    local backup_dir="$SITES_DIR/$domain/backups"
    local action="$2"
    local max_age_days="${3}"
    local formatted_msg_cleaning_old_backups

    # Check if the backup directory exists
    if [[ ! -d "$backup_dir" ]]; then
        print_and_debug error "$MSG_NOT_FOUND $backup_dir"
        mkdir -p "$backup_dir"
        debug_log "Backup directory $backup_dir created because it did not exist."
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

        max_age_days="$(get_input_or_test_value "Enter the number of days to keep backups: " "${TEST_MAX_AGE_DAYS:-7}")"
        echo "You selected to keep backups for $max_age_days days."
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
