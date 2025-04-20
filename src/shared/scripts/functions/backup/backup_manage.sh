# ================================================
# 📋 backup_prompt_backup_manage – Menu for managing backups
# ================================================
backup_prompt_backup_manage() {
    local domain
    safe_source "$CLI_DIR/backup_manage.sh"
    website_get_selected domain
    if [[ -z "$domain" ]]; then
        print_and_debug error "$ERROR_MISSING_PARAM: --domain must be provided"
        return 1
    fi
    _is_valid_domain "$domain" || return 1
    print_msg info "$MSG_WEBSITE_SELECTED: $domain"

    # === Choose action: list or clean ===
    print_msg label "$PROMPT_ENTER_ACTION_NUMBER"
    select action_choice in "list" "clean"; do
        case "$action_choice" in
        list | clean)
            echo ""
            action="$action_choice"
            break
            ;;
        *)
            print_and_debug error "$ERROR_INVALID_CHOICE: $action_choice"
            ;;
        esac
    done

    backup_cli_manage --domain="$domain" --action="$action"
}

# ================================================
# 🧠 backup_logic_manage – Handle backup listing or cleaning
# ================================================
# Parameters:
#   $1 - domain
#   $2 - action (list | clean)
#   $3 - max_age_days (optional, for cleaning)
backup_logic_manage() {
    local domain="$1"
    local action="$2"
    local max_age_days="${3:-7}"
    local backup_dir="$SITES_DIR/$domain/backups"
    _is_valid_domain "$domain" || return 1
    # Ensure backup directory exists
    if ! is_directory_exist "$backup_dir"; then
        print_and_debug error "$(printf "$ERROR_DIRECTORY_NOT_FOUND" "$backup_dir")"
        mkdir -p "$backup_dir"
        return 1
    fi

    case "$action" in
    list)
        print_msg step "$MSG_BACKUP_LISTING: $domain"

        print_msg label "$LABEL_BACKUP_FILE_LIST"
        if [[ "$(uname)" == "Darwin" ]]; then
            ls -lt "$backup_dir" | awk '{print $6, $7, $8, $9}' | grep ".tar.gz"
            print_msg label "$LABEL_BACKUP_DB_LIST"
            ls -lt "$backup_dir" | awk '{print $6, $7, $8, $9}' | grep ".sql"
        else
            find "$backup_dir" -type f -printf '%TY-%Tm-%Td %TH:%TM %p\n' | sort -r | grep ".tar.gz"
            print_msg label "$LABEL_BACKUP_DB_LIST"
            find "$backup_dir" -type f -printf '%TY-%Tm-%Td %TH:%TM %p\n' | sort -r | grep ".sql"
        fi
        ;;

    clean)
        max_age_days="$(get_input_or_test_value "$PROMPT_BACKUP_MAX_AGE" "${TEST_MAX_AGE_DAYS:-$max_age_days}")"
        print_msg success "$(printf "$STEP_SET_MAX_AGE_DAYS" "$max_age_days")"
        print_msg step "$(printf "$STEP_CLEANING_OLD_BACKUPS" "$max_age_days" "$backup_dir")"

        if [[ "$DEBUG_MODE" == true ]]; then
            local old_files_count
            old_files_count=$(find "$backup_dir" -type f \( -name "*.tar.gz" -o -name "*.sql" \) -mtime +$max_age_days | wc -l)
            debug_log "Found $old_files_count old backup files (>$max_age_days days)"
        fi

        find "$backup_dir" -type f \( -name "*.tar.gz" -o -name "*.sql" \) -mtime +$max_age_days -exec rm -f {} \;
        print_msg success "$SUCCESS_BACKUP_CLEAN"
        ;;

    *)
        print_and_debug error "$ERROR_BACKUP_INVALID_ACTION"
        debug_log "Invalid action: $action"
        return 1
        ;;
    esac
}
