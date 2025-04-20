#!/bin/bash
# =============================================
# 🔤 convert_weekday – Convert weekday number to label
# =============================================
# Description:
#   - Maps a weekday number (0–6) to its corresponding label (Sunday–Saturday).
#
# Parameters:
#   $1 - weekday number (0–6)
#
# Globals:
#   LABEL_SUNDAY, LABEL_MONDAY, ..., LABEL_SATURDAY
#
# Returns:
#   - Echoes the corresponding weekday label
# =============================================
convert_weekday() {
    case $1 in
    0) echo "$LABEL_SUNDAY" ;;
    1) echo "$LABEL_MONDAY" ;;
    2) echo "$LABEL_TUESDAY" ;;
    3) echo "$LABEL_WEDNESDAY" ;;
    4) echo "$LABEL_THURSDAY" ;;
    5) echo "$LABEL_FRIDAY" ;;
    6) echo "$LABEL_SATURDAY" ;;
    *) echo "Unknown" ;;
    esac
}

# =============================================
# ⏰ cron_translate – Convert cron expression to human-readable text
# =============================================
# Description:
#   - Translates a cron expression into a readable string using defined labels.
#
# Parameters:
#   $1 - cron expression string (5-part)
#
# Globals:
#   LABEL_EVERYDAY, LABEL_EVERY_WEEK, LABEL_EVERY_MONTH,
#   LABEL_TIME_AT, LABEL_DATE_ON, LABEL_CUSTOM_SCHEDULE
#
# Returns:
#   - Echoes a formatted string describing the schedule
# =============================================
cron_translate() {
    local cron_exp="$1"

    # Split cron fields
    local minute
    minute=$(echo "$cron_exp" | awk '{print $1}')
    local hour
    hour=$(echo "$cron_exp" | awk '{print $2}')
    local day
    day=$(echo "$cron_exp" | awk '{print $3}')
    local month
    month=$(echo "$cron_exp" | awk '{print $4}')
    local weekday
    weekday=$(echo "$cron_exp" | awk '{print $5}')

    # Determine time
    local time="$hour:$minute"

    # Determine frequency
    if [[ "$day" == "*" && "$month" == "*" && "$weekday" == "*" ]]; then
        schedule="$LABEL_EVERYDAY $LABEL_TIME_AT $time"
    elif [[ "$day" == "*" && "$month" == "*" && "$weekday" != "*" ]]; then
        schedule="$LABEL_EVERY_WEEK $LABEL_TIME_AT $time $LABEL_DATE_ON $(convert_weekday "$weekday")"
    elif [[ "$day" != "*" && "$month" == "*" ]]; then
        schedule="$LABEL_EVERY_MONTH $LABEL_TIME_AT $time, $LABEL_DATE_ON $day"
    else
        schedule="$LABEL_CUSTOM_SCHEDULE: $cron_exp"
    fi

    echo "$schedule"
}

backup_prompt_list_schedule() {
    print_msg title "$TITLE_BACKUP_SCHEDULE_LIST"

    local has_schedule=false

    mapfile -t sites < <(website_list)

    for domain in "${sites[@]}"; do
        local enabled interval storage rclone_storage

        enabled=$(json_get_site_value "$domain" "backup_schedule.enabled")
        interval=$(json_get_site_value "$domain" "backup_schedule.interval_days")
        storage=$(json_get_site_value "$domain" "backup_schedule.storage")
        rclone_storage=$(json_get_site_value "$domain" "backup_schedule.rclone_storage")

        if [[ "$enabled" == "true" ]]; then
            has_schedule=true
            local schedule_text="⏰ Every ${interval:-1} day(s)"
            local storage_text="📦 $storage"
            [[ "$storage" == "cloud" && -n "$rclone_storage" ]] && storage_text+=" → $rclone_storage"

            echo -e "${YELLOW}• ${CYAN}$domain${NC}"
            echo -e "   $schedule_text"
            echo -e "   $storage_text"
            echo ""
        fi
    done

    if [[ "$has_schedule" == false ]]; then
        print_msg info "$INFO_BACKUP_NO_WEBSITE_SCHEDULED"
    fi
}
# =============================================
# ❌ schedule_backup_remove – Remove backup cron job for a website
# =============================================
# Description:
#   - Removes backup cron jobs for the selected domain using a filtered crontab.
#
# Globals:
#   BACKUP_RUNNER, domain
#
# Returns:
#   - None
# =============================================
schedule_backup_remove() {
    local domain
    if ! website_get_selected domain; then
        return 1
    fi
    _is_valid_domain "$domain" || return 1
    local temp_cron
    temp_cron=$(mktemp)
    crontab -l 2>/dev/null | grep -v "$BACKUP_RUNNER $domain" >"$temp_cron"
    crontab "$temp_cron"
    rm -f "$temp_cron"

    print_msg
}

# =============================================
# 📅 backup_schedule_menu – Interactive cron job management menu
# =============================================
# Description:
#   - Displays a CLI menu for listing or removing scheduled backups via cron.
#
# Globals:
#   TITLE_MENU_BACKUP_SCHEDULE_MANAGEMENT,
#   LABEL_MENU_BACKUP_SCHEDULE_VIEW, LABEL_MENU_BACKUP_SCHEDULE_REMOVE,
#   MSG_BACK, PROMPT_SELECT_OPTION, TEST_CHOICE, ERROR_SELECT_OPTION_INVALID
#
# Returns:
#   - None
# =============================================
backup_schedule_menu() {
    while true; do
        echo -e "${BLUE}============================${NC}"
        echo -e "${BLUE}   $TITLE_MENU_BACKUP_SCHEDULE_MANAGEMENT (CRON)   ${NC}"
        echo -e "${BLUE}============================${NC}"
        print_msg label "${GREEN}1)${NC} $LABEL_MENU_BACKUP_SCHEDULE_VIEW"
        print_msg label "${GREEN}2)${NC} $LABEL_MENU_BACKUP_SCHEDULE_REMOVE"
        print_msg label "${GREEN}3)${NC} $MSG_BACK"
        echo -e "${BLUE}============================${NC}"

        choice=$(get_input_or_test_value "$PROMPT_SELECT_OPTION" "${TEST_CHOICE:-3}")
        case "$choice" in
        1) backup_prompt_list_schedule ;;
        2) schedule_backup_remove ;;
        3) break ;;
        *)
            print_msg error "$ERROR_SELECT_OPTION_INVALID"
            sleep 1
            ;;
        esac
    done
}
