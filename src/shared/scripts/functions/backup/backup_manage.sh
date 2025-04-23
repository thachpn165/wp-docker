# ================================================
# 📋 backup_prompt_backup_manage – Menu for managing backups
# ================================================
backup_prompt_backup_manage() {
    local domain
    safe_source "$CLI_DIR/backup_manage.sh"
    if ! website_get_selected domain; then
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
    local max_age_days="$3"
    local backup_dir="$SITES_DIR/$domain/backups"
    _is_valid_domain "$domain" || return 1
    # Ensure backup directory exists
    if ! _is_directory_exist "$backup_dir"; then
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
        # Chỉ hỏi nếu biến chưa có
        if [[ -z "$max_age_days" ]]; then
            max_age_days="$(get_input_or_test_value "$PROMPT_BACKUP_MAX_AGE" "${TEST_MAX_AGE_DAYS:-7}")"
        fi


        print_msg step "$(printf "$STEP_CLEANING_OLD_BACKUPS" "$max_age_days" "$backup_dir")"

        # Tìm danh sách tập tin cần xoá
        old_files=$(find "$backup_dir" -type f \( -name "*.tar.gz" -o -name "*.sql" \) -mtime +"$max_age_days")

        if [[ -z "$old_files" ]]; then
            print_msg info "$INFO_NO_OLD_BACKUPS_FOUND"
            return 0
        fi

        # Hiển thị danh sách file
        print_msg info "📄 $INFO_OLD_BACKUP_FILES_FOUND"
        echo "$old_files" | nl -w2 -s'. '

        # Xác nhận xoá
        if confirm_action "$CONFIRM_DELETE_OLD_BACKUPS"; then
            echo "$old_files" | while read -r file; do
                rm -f "$file"
            done
            print_msg success "$SUCCESS_BACKUP_CLEAN"
        else
            print_msg warning "$WARNING_BACKUP_CLEAN_ABORTED"
        fi
        ;;

    *)
        print_and_debug error "$ERROR_BACKUP_INVALID_ACTION"
        debug_log "Invalid action: $action"
        return 1
        ;;
    esac
}
