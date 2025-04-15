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

# =============================================
# 📋 schedule_backup_list – List scheduled backup cron jobs per website
# =============================================
# Description:
#   - Displays all websites with active backup cron jobs and lets the user view their details.
#
# Globals:
#   PROMPT_BACKUP_SELECT_WEB_VIEW_SCHEDULE, INFO_BACKUP_SCHEDULE_WEBSITE_LIST,
#   INFO_BACKUP_VIEW_SCHEDULED_WEBSITE, INFO_BACKUP_SCHEDULE_LIST_FOR_WEBSITE,
#   ERROR_BACKUP_NO_WEBSITE_SCHENDULED, ERROR_BACKUP_NOT_SCHEDULED_FOR_WEBSITE,
#   ERROR_SELECT_OPTION_INVALID, BACKUP_RUNNER
#
# Returns:
#   - Displays formatted table of schedules
#   - Returns 1 if no scheduled websites are found
# =============================================
schedule_backup_list() {

    print_msg info "$INFO_BACKUP_SCHEDULE_WEBSITE_LIST"

    # Get website list from crontab
    mapfile -t websites < <(crontab -l 2>/dev/null | grep "backup_website.sh" | awk -F '--domain=' '{print $2}' | awk '{print $1}' | sort -u)

    if [[ ${#websites[@]} -eq 0 ]]; then
        print_msg error "$ERROR_BACKUP_NO_WEBSITE_SCHENDULED"
        return 1
    fi

    # Display website list
    print_msg label "$PROMPT_BACKUP_SELECT_WEB_VIEW_SCHEDULE"
    select SITE_DOMAIN in "${websites[@]}"; do
        if [[ -n "$domain" ]]; then
            print_msg info "$INFO_BACKUP_VIEW_SCHEDULED_WEBSITE: $domain"
            break
        else
            print_msg error "$ERROR_SELECT_OPTION_INVALID"
        fi
    done

    # Fetch cron jobs related to the selected website
    cron_jobs=$(crontab -l 2>/dev/null | grep "backup_website.sh --domain=$domain")

    if [[ -z "$cron_jobs" ]]; then
        print_msg error "$ERROR_BACKUP_NOT_SCHEDULED_FOR_WEBSITE: $domain"
        return 1
    else
        print_msg info "$INFO_BACKUP_SCHEDULE_LIST_FOR_WEBSITE: $domain"
        echo -e "${YELLOW}Frequency | Website | Log Path${NC}"
        echo -e "${MAGENTA}------------------------------------------------------${NC}"
        
        # Translate cron time and display full details
        while IFS= read -r line; do
            cron_exp=$(echo "$line" | awk '{print $1, $2, $3, $4, $5}')
            schedule=$(cron_translate "$cron_exp")
            website=$(echo "$line" | awk -F '--domain=' '{print $2}' | awk '{print $1}')   # Get exact website name
            log_path=$(echo "$line" | awk -F '>> ' '{print $2}' | awk '{print $1}')               # Get exact log path
            
            echo -e "⏰ $schedule | 🌐 $website | 📝 $log_path"
        done <<< "$cron_jobs"

        echo -e "${MAGENTA}------------------------------------------------------${NC}"
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
    select_website || return

    local temp_cron
    temp_cron=$(mktemp)
    crontab -l 2>/dev/null | grep -v "$BACKUP_RUNNER $domain" > "$temp_cron"
    crontab "$temp_cron"
    rm -f "$temp_cron"

    print_msg 
}

# =============================================
# 📅 manage_cron_menu – Interactive cron job management menu
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
manage_cron_menu() {
    while true; do
        echo -e "${BLUE}============================${NC}"
        echo -e "${BLUE}   $TITLE_MENU_BACKUP_SCHEDULE_MANAGEMENT (CRON)   ${NC}"
        echo -e "${BLUE}============================${NC}"
        print_msg label "${GREEN}1)${NC} $LABEL_MENU_BACKUP_SCHEDULE_VIEW"
        print_msg label "${GREEN}2)${NC} $LABEL_MENU_BACKUP_SCHEDULE_REMOVE"
        print_msg label "${GREEN}3)${NC} $MSG_BACK"
        echo -e "  ${GREEN}[3]${NC} 🔙 Back"
        echo -e "${BLUE}============================${NC}"

        choice=$(get_input_or_test_value "$PROMPT_SELECT_OPTION" "${TEST_CHOICE:-3}")
        case "$choice" in
            1) schedule_backup_list ;;
            2) schedule_backup_remove ;;
            3) break ;;
            *)
                print_msg error "$ERROR_SELECT_OPTION_INVALID"
                sleep 1
                ;;
        esac
    done
}
