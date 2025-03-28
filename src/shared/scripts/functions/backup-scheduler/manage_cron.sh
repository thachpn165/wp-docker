#!/bin/bash

CONFIG_FILE="shared/config/config.sh"

# Determine absolute path of `config.sh`
while [ ! -f "$CONFIG_FILE" ]; do
    CONFIG_FILE="../$CONFIG_FILE"
    if [ "$(pwd)" = "/" ]; then
        echo "❌ Error: config.sh not found!" >&2
        exit 1
    fi
done

source "$CONFIG_FILE"

# Define backup runner file
BACKUP_RUNNER="$SCRIPTS_FUNCTIONS_DIR/backup-manager/backup_runner.sh"

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
        schedule="Daily at $time"
    elif [[ "$day" == "*" && "$month" == "*" && "$weekday" != "*" ]]; then
        schedule="Weekly at $time, on $(convert_weekday "$weekday")"
    elif [[ "$day" != "*" && "$month" == "*" ]]; then
        schedule="Monthly at $time, on day $day"
    else
        schedule="Custom schedule: $cron_exp"
    fi

    echo "$schedule"
}

# Convert weekday from number to text
convert_weekday() {
    case $1 in
        0) echo "Sunday" ;;
        1) echo "Monday" ;;
        2) echo "Tuesday" ;;
        3) echo "Wednesday" ;;
        4) echo "Thursday" ;;
        5) echo "Friday" ;;
        6) echo "Saturday" ;;
        *) echo "Unknown" ;;
    esac
}

# Display list of websites with backup schedules and allow viewing details
schedule_backup_list() {
    echo -e "${BLUE}📅 List of websites with backup schedules:${NC}"

    # Get website list from crontab
    local websites=($(crontab -l 2>/dev/null | grep "backup_runner.sh" | awk -F 'backup_runner.sh ' '{print $2}' | awk '{print $1}' | sort -u))

    if [[ ${#websites[@]} -eq 0 ]]; then
        echo -e "${RED}❌ No websites have backup schedules.${NC}"
        return 1
    fi

    # Display website list
    echo -e "${YELLOW}🔹 Select a website to view its backup schedule:${NC}"
    select SITE_NAME in "${websites[@]}"; do
        if [[ -n "$SITE_NAME" ]]; then
            echo -e "${GREEN}✅ Viewing backup schedule for: $SITE_NAME${NC}"
            break
        else
            echo -e "${RED}❌ Invalid selection!${NC}"
        fi
    done

    # Determine operating system (macOS or Linux)
    if [[ "$(uname)" == "Darwin" ]]; then
        cron_jobs=$(crontab -l 2>/dev/null | grep "backup_runner.sh $SITE_NAME")
    else
        cron_jobs=$(crontab -l 2>/dev/null | grep "$SCRIPTS_FUNCTIONS_DIR/backup-scheduler/backup_runner.sh $SITE_NAME")
    fi

    if [[ -z "$cron_jobs" ]]; then
        echo -e "${RED}❌ No backup schedule found for website: $SITE_NAME${NC}"
    else
        echo -e "${GREEN}📜 Backup schedule for $SITE_NAME:${NC}"
        echo -e "${YELLOW}Frequency | Website | Log Path${NC}"
        echo -e "${MAGENTA}------------------------------------------------------${NC}"
        
        # Translate cron time and display full details
        while IFS= read -r line; do
            cron_exp=$(echo "$line" | awk '{print $1, $2, $3, $4, $5}')
            schedule=$(cron_translate "$cron_exp")
            website=$(echo "$line" | awk -F 'backup_runner.sh ' '{print $2}' | awk '{print $1}')   # Get exact website name
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
    crontab -l 2>/dev/null | grep -v "$BACKUP_RUNNER $SITE_NAME" > "$temp_cron"
    crontab "$temp_cron"
    rm -f "$temp_cron"

    echo -e "${GREEN}✅ Removed backup schedule for website: $SITE_NAME${NC}"
}

# Display crontab management menu
manage_cron_menu() {
    while true; do
        echo -e "${BLUE}============================${NC}"
        echo -e "${BLUE}   ⚙️ BACKUP SCHEDULE MANAGEMENT (CRON)   ${NC}"
        echo -e "${BLUE}============================${NC}"
        echo -e "  ${GREEN}[1]${NC} 📜 View backup schedules"
        echo -e "  ${GREEN}[2]${NC} ❌ Remove website backup schedule"
        echo -e "  ${GREEN}[3]${NC} 🔙 Back"
        echo -e "${BLUE}============================${NC}"

        read -p "🔹 Select an option (1-3): " choice
        case "$choice" in
            1) schedule_backup_list ;;
            2) schedule_backup_remove ;;
            3) echo -e "${GREEN}🔙 Returning to main menu.${NC}"; break ;;
            *) echo -e "${RED}❌ Invalid option, please try again!${NC}" ;;
        esac
    done
}

# Check if a website has a backup schedule
schedule_backup_exists() {
    local site_name="$1"

    # Check if backup_runner.sh exists in crontab for that website
    if crontab -l 2>/dev/null | grep -q "backup_runner.sh $site_name"; then
        return 0  # Backup schedule exists
    else
        return 1  # No backup schedule
    fi
}