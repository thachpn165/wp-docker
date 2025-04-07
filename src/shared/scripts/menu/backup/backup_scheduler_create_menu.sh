#!/bin/bash
# ✅ Load configuration from any directory
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
SEARCH_PATH="$SCRIPT_PATH"
while [[ "$SEARCH_PATH" != "/" ]]; do
  if [[ -f "$SEARCH_PATH/shared/config/load_config.sh" ]]; then
    source "$SEARCH_PATH/shared/config/load_config.sh"
    load_config_file
    break
  fi
  SEARCH_PATH="$(dirname "$SEARCH_PATH")"
done

# Load functions for backup
source "$FUNCTIONS_DIR/backup_loader.sh"

# === Define the backup scheduler function ===
backup_scheduler_create() {
  # === Select website ===
  select_website || return
  if [[ -z "$domain" ]]; then
    print_msg error "$ERROR_NO_WEBSITE_SELECTED"
    return 1
  fi

  # === Choose schedule time (Cron format) ===
  print_msg info "$INFO_SELECT_BACKUP_SCHEDULE"
  echo "1. Every day at 3:00 AM (0 3 * * *)"
  echo "2. Every Sunday at 2:00 AM (0 2 * * SUN)"
  echo "3. Every Monday at 1:00 AM (0 1 * * MON)"
  echo "4. Custom cron time"

  schedule_choice=$(get_input_or_test_value "${TEST_SCHEDULE_CHOICE:-1}" "$PROMPT_SELECT_OPTION")

  case "$schedule_choice" in
    1) schedule_time="0 3 * * *" ;;
    2) schedule_time="0 2 * * SUN" ;;
    3) schedule_time="0 1 * * MON" ;;
    4)
      schedule_time=$(get_input_or_test_value "${TEST_CUSTOM_CRON:-0 3 * * *}" "$PROMPT_ENTER_CUSTOM_CRON")
      ;;
    *)
      print_msg warning "$WARNING_INPUT_INVALID"
      return 1
      ;;
  esac

  # === Choose storage option ===
  print_msg info "$INFO_SELECT_STORAGE_LOCATION"
  echo "  [1] 💾 $LABEL_BACKUP_LOCAL"
  echo "  [2] ☁️  $LABEL_BACKUP_CLOUD"
  storage_choice=$(get_input_or_test_value "${TEST_STORAGE_CHOICE:-1}" "$PROMPT_SELECT_STORAGE_OPTION")

  local storage="local"
  local rclone_storage=""
  if [[ "$storage_choice" == "2" ]]; then
    print_msg info "$INFO_RCLONE_READING_STORAGE_LIST"

    # Lấy danh sách storage từ rclone.conf
    mapfile -t storages < <(rclone_storage_list)

    if [[ ${#storages[@]} -eq 0 ]]; then
      print_msg warning "$WARNING_RCLONE_STORAGE_EMPTY"
      return 1
    fi

    print_msg label "$LABEL_MENU_RCLONE_AVAILABLE_STORAGE:"
    for s in "${storages[@]}"; do
      echo "  ➜ $s"
    done

    print_msg question "$PROMPT_ENTER_STORAGE_NAME"
    while true; do
      rclone_storage=$(get_input_or_test_value "$TEST_RCLONE_STORAGE" "$PROMPT_ENTER_STORAGE_NAME")
      rclone_storage=$(echo "$rclone_storage" | xargs)

      if [[ " ${storages[*]} " =~ " ${rclone_storage} " ]]; then
        print_msg success "$(printf "$SUCCESS_RCLONE_STORAGE_SELECTED %s" "$rclone_storage")"
        storage="cloud"
        break
      else
        print_msg warning "$WARNING_INPUT_INVALID"
      fi
    done
  fi

  # === Setup variables for crontab ===
  local log_file="$SITES_DIR/$domain/logs/wp-backup.log"
 