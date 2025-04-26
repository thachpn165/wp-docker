#!/bin/bash
# ==================================================
# File: manage_cron.sh
# Description: Functions to manage backup schedules via cron, including listing, removing, 
#              and interacting with scheduled backups.
# Functions:
#   - backup_prompt_list_schedule: Display a list of scheduled backups.
#       Parameters: None.
#   - schedule_backup_remove: Remove a backup schedule for a specific website.
#       Parameters: None.
#   - backup_schedule_menu: Interactive menu for managing backup schedules.
#       Parameters: None.
# ==================================================

backup_prompt_list_schedule() {
    print_msg title "$TITLE_BACKUP_SCHEDULE_LIST"

    local has_schedule=false
    local now_ts
    now_ts=$(date +%s)

    mapfile -t sites < <(website_list)

    if [[ ${#sites[@]} -eq 0 ]]; then
        print_msg warning "$WARNING_NO_WEBSITE_FOUND"
        return 1
    fi

    for domain in "${sites[@]}"; do
        local enabled interval storage rclone_storage
        enabled=$(json_get_site_value "$domain" "backup_schedule.enabled")
        interval=$(json_get_site_value "$domain" "backup_schedule.interval_days")
        storage=$(json_get_site_value "$domain" "backup_schedule.storage")
        rclone_storage=$(json_get_site_value "$domain" "backup_schedule.rclone_storage")

        if [[ "$enabled" == "true" ]]; then
            has_schedule=true

            local next_ts next_date
            next_ts=$((now_ts + (interval * 86400)))
            next_date=$(date -d "@$next_ts" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || gdate -d "@$next_ts" "+%Y-%m-%d %H:%M:%S")

            local schedule_text="⏰ $LABEL_BACKUP_EVERY ${interval:-1} $LABEL_BACKUP_DAYS"
            local next_text="🕒 $LABEL_BACKUP_NEXT_RUN: $next_date"
            local storage_text="📦 $storage"
            [[ "$storage" == "cloud" && -n "$rclone_storage" ]] && storage_text+=" → $rclone_storage"

            echo -e "${YELLOW}• ${CYAN}$domain${NC}"
            echo -e "   $schedule_text"
            echo -e "   $next_text"
            echo -e "   $storage_text"
            echo ""
        fi
    done

    if [[ "$has_schedule" == false ]]; then
        print_msg info "$INFO_BACKUP_NO_WEBSITE_SCHEDULED"
    fi
}

schedule_backup_remove() {
    print_msg title "$TITLE_BACKUP_REMOVE_SCHEDULE"

    local domain
    website_get_selected domain || return 1
    _is_valid_domain "$domain" || return 1

    local enabled
    enabled=$(json_get_site_value "$domain" "backup_schedule.enabled")

    if [[ "$enabled" != "true" ]]; then
        print_msg error "$ERROR_BACKUP_NO_SCHEDULE_FOUND_FOR_SITE: $domain)"
        return 1
    fi

    local interval storage rclone_storage
    interval=$(json_get_site_value "$domain" "backup_schedule.interval_days")
    storage=$(json_get_site_value "$domain" "backup_schedule.storage")
    rclone_storage=$(json_get_site_value "$domain" "backup_schedule.rclone_storage")

    print_msg info "$INFO_BACKUP_CURRENT_SCHEDULE: ${CYAN}$domain${NC}:"
    echo -e "   ⏰ $LABEL_BACKUP_EVERY ${interval:-1} $LABEL_BACKUP_DAYS"
    if [[ "$storage" == "local" ]]; then
        echo -e "   📦 Storage: Local"
    elif [[ "$storage" == "cloud" ]]; then
        echo -e "   ☁️ Storage: Cloud → ${YELLOW}$rclone_storage${NC}"
    fi
    echo ""

    confirm_action "$QUESTION_BACKUP_CONFIRM_REMOVE_SCHEDULE: $domain"
    if [[ $? -ne 0 ]]; then
        print_msg info "$MSG_BACKUP_REMOVE_CANCELLED"
        return 0
    fi

    json_delete_site_key "$domain" "backup_schedule"
    print_msg success "$SUCCESS_BACKUP_SCHEDULE_REMOVED: $domain"
}

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