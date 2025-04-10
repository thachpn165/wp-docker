#!/bin/bash
# Convert weekday from number to text
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

# Convert cron time to human-readable format
cron_translate() {
    local cron_exp="$1"

    # Split cron fields
    local minute=$(echo "$cron_exp" | awk '{print $1}')
    local hour=$(echo "$cron_exp" | awk '{print $2}')
    local day=$(echo "$cron_exp" | awk '{print $3}')
    local month=$(echo "$cron_exp" | awk '{print $4}')
    local weekday=$(echo "$cron_exp" | awk '{print $5}')

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

# Display list of websites with backup schedules and allow viewing details
schedule_backup_list() {
    echo -e "${BLUE}📅 List of websites with backup schedules:${NC}"

    # Get website list from crontab
    local websites=($(crontab -l 2>/dev/null | grep "backup_website.sh" | awk -F '--domain=' '{print $2}' | awk '{print $1}' | sort -u))

    if [[ ${#websites[@]} -eq 0 ]]; then
        echo -e "${RED}${CROSSMARK} No websites have backup schedules.${NC}"
        return 1
    fi

    # Display website list
    echo -e "${YELLOW}🔹 Select a website to view its backup schedule:${NC}"
    select SITE_DOMAIN in "${websites[@]}"; do
        if [[ -n "$domain" ]]; then
            echo -e "${GREEN}${CHECKMARK} Viewing backup schedule for: $domain${NC}"
            break
        else
            echo -e "${RED}${CROSSMARK} Invalid selection!${NC}"
        fi
    done

    # Fetch cron jobs related to the selected website
    cron_jobs=$(crontab -l 2>/dev/null | grep "backup_website.sh --domain=$domain")

    if [[ -z "$cron_jobs" ]]; then
        echo -e "${RED}${CROSSMARK} No backup schedule found for website: $domain${NC}"
    else
        echo -e "${GREEN}📜 Backup schedule for $domain:${NC}"
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

# Remove backup schedule for a website
schedule_backup_remove() {
    select_website || return

    local temp_cron=$(mktemp)
    crontab -l 2>/dev/null | grep -v "$BACKUP_RUNNER $domain" > "$temp_cron"
    crontab "$temp_cron"
    rm -f "$temp_cron"

    echo -e "${GREEN}${CHECKMARK} Removed backup schedule for website: $domain${NC}"
}

# Display crontab management menu
manage_cron_menu() {
    while true; do
        echo -e "${BLUE}============================${NC}"
        echo -e "${BLUE}   ⚙️ BACKUP SCHEDULE MANAGEMENT (CRON)   ${NC}"
        echo -e "${BLUE}============================${NC}"
        echo -e "  ${GREEN}[1]${NC} 📜 View backup schedules"
        echo -e "  ${GREEN}[2]${NC} ${CROSSMARK} Remove website backup schedule"
        echo -e "  ${GREEN}[3]${NC} 🔙 Back"
        echo -e "${BLUE}============================${NC}"

        [[ "$TEST_MODE" != true ]] && read -p "🔹 Select an option (1-3): " choice
        case "$choice" in
            1) schedule_backup_list ;;
            2) schedule_backup_remove ;;
            3) echo -e "${GREEN}🔙 Returning to main menu.${NC}"; break ;;
            *) echo -e "${RED}${CROSSMARK} Invalid option, please try again!${NC}" ;;
        esac
    done
}

# Check if a website has a backup schedule
schedule_backup_exists() {
    local domain="$1"

    # Check if backup_runner.sh exists in crontab for that website
    if crontab -l 2>/dev/null | grep -q "backup_runner.sh $domain"; then
        return 0  # Backup schedule exists
    else
        return 1  # No backup schedule
    fi
}