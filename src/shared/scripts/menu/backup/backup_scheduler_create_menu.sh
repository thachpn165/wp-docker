#!/bin/bash

# === Load config & backup_loader.sh ===
if [[ -z "$PROJECT_DIR" ]]; then
  SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
  while [[ "$SCRIPT_PATH" != "/" ]]; do
    if [[ -f "$SCRIPT_PATH/shared/config/config.sh" ]]; then
      PROJECT_DIR="$SCRIPT_PATH"
      break
    fi
    SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
  done
fi

CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "$MSG_NOT_FOUND: $CONFIG_FILE" >&2
  exit 1
fi
source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/backup_loader.sh"

# === Define the backup scheduler function ===
backup_scheduler_create() {
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

# === Execute ===
backup_scheduler_create
