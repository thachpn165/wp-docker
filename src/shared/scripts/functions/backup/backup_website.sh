#shellcheck disable=SC1091
backup_prompt_create_schedule() {
  # === Select website ===
  select_website
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
  (crontab -l 2>/dev/null; echo "$schedule_time $backup_command >> $backup_log_file 2>&1") | crontab -

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

backup_prompt_backup_web() {
    # 📋 Hiển thị danh sách website để chọn (dùng select_website)
    select_website
    if [[ -z "$domain" ]]; then
        echo -e "${RED}${CROSSMARK} No website selected.${NC}"
        exit 1
    fi

    # === Choose storage: local or cloud ===
    echo -e "${YELLOW}📂 Choose storage option:${NC}"
    select storage_choice in "local" "cloud"; do
        case $storage_choice in
        local)
            echo "You selected local storage."
            storage="local"
            break
            ;;
        cloud)
            echo "You selected cloud storage."
            storage="cloud"
            break
            ;;
        *)
            echo "${CROSSMARK} Invalid option. Please select either 'local' or 'cloud'."
            ;;
        esac
    done

    # === If cloud storage is selected, ask for rclone storage selection ===
    if [[ "$storage" == "cloud" ]]; then
        echo -e "${YELLOW}📂 Fetching storage list from rclone.conf...${NC}"

        # Get list of storage names from rclone.conf, removing brackets
        mapfile -t rclone_storages < <(grep -o '^\[.*\]' "$RCLONE_CONFIG_FILE" | sed 's/\[\(.*\)\]/\1/g')

        # Check if there are storages available
        if [[ ${#rclone_storages[@]} -eq 0 ]]; then
            echo -e "${RED}${CROSSMARK} No storage configured in rclone.conf! Please run 'wpdocker' > 'Rclone Management' > 'Setup Rclone' to configure Rclone.${NC}"
            exit 1
        fi

        # Display list of available rclone storages
        echo -e "${BLUE}Available Rclone Storages:${NC}"
        for i in "${!rclone_storages[@]}"; do
            echo "[$i] ${rclone_storages[$i]}"
        done

        # Prompt the user to select a storage
        read -p "Select storage (number): " selected_storage_index

        if [[ -z "${rclone_storages[$selected_storage_index]}" ]]; then
            echo -e "${RED}${CROSSMARK} Invalid selection. Exiting.${NC}"
            exit 1
        fi

        selected_storage="${rclone_storages[$selected_storage_index]}"
        echo "You selected storage: $selected_storage"
    fi

    # === Pass selected parameters to the backup logic ===
    backup_logic_website "$domain" "$storage" "$selected_storage"

}

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
    source "$CLI_DIR/backup_website.sh"

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
    db_backup_file=$(bash "$CLI_DIR/database_export.sh" --domain="$domain" | tail -n 1)
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
