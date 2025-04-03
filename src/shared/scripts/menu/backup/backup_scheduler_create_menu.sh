#!/bin/bash

# === Load config & website_loader.sh ===
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
  echo "${CROSSMARK} Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi
source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/backup_loader.sh"

# === Define the backup scheduler function ===
backup_scheduler_create() {
    # === Select website ===
    select_website

    # Ensure site is selected
    if [[ -z "$SITE_NAME" ]]; then
        echo "${CROSSMARK} No website selected. Exiting."
        exit 1
    fi

    echo "Selected site: $SITE_NAME"

    # === Choose schedule time (Cron format) ===
    echo -e "${YELLOW}📅 Select the time for the backup to run (Cron format):${NC}"
    echo "1. Every day at 3:00 AM (0 3 * * *)"
    echo "2. Every Sunday at 2:00 AM (0 2 * * SUN)"
    echo "3. Every Monday at 1:00 AM (0 1 * * MON)"
    echo "4. Custom cron time"
    read -p "Enter your choice (1-4): " schedule_choice

    case "$schedule_choice" in
        1)
            schedule_time="0 3 * * *"
            ;;
        2)
            schedule_time="0 2 * * SUN"
            ;;
        3)
            schedule_time="0 1 * * MON"
            ;;
        4)
            read -p "Enter custom cron time (e.g., '0 3 * * *'): " schedule_time
            ;;
        *)
            echo "${CROSSMARK} Invalid choice"
            exit 1
            ;;
    esac

    # === Choose storage for backup ===
    echo -e "${YELLOW}${SAVE} Select where to store the backup:${NC}"
    select storage_choice in "local" "cloud"; do
        case $storage_choice in
            local)
                storage="local"
                break
                ;;
            cloud)
                storage="cloud"
                # === Select rclone storage for cloud backup ===
                echo -e "${YELLOW}📂 Available Rclone Storages:${NC}"
                storages=($(grep -oP '^\[\K[^\]]+' "$RCLONE_CONFIG_FILE"))

                if [[ ${#storages[@]} -eq 0 ]]; then
                    echo -e "${RED}${CROSSMARK} No storage available in rclone.conf. Please set up Rclone first!${NC}"
                    exit 1
                fi

                for i in "${!storages[@]}"; do
                    echo "  ${GREEN}[$i]${NC} ${storages[$i]}"
                done

                read -p "Enter the number of the storage you want to use: " storage_index
                rclone_storage="${storages[$storage_index]}"

                # Validate rclone_storage
                if [[ -z "$rclone_storage" ]]; then
                    echo -e "${RED}${CROSSMARK} Invalid storage selection!${NC}"
                    exit 1
                fi

                break
                ;;
            *)
                echo "${CROSSMARK} Invalid choice. Please select either 'local' or 'cloud'."
                ;;
        esac
    done

    # === Set log file path using local variable ===
    local backup_log_file="$SITES_DIR/$SITE_NAME/logs/backup_schedule.logs"

    # === Schedule the backup in crontab ===
    backup_command="bash $CLI_DIR/backup_website.sh --site_name=$SITE_NAME --storage=$storage"
    if [[ "$storage" == "cloud" ]]; then
        backup_command="$backup_command --rclone_storage=$rclone_storage"
    fi

    # Add the backup job to crontab
    (crontab -l 2>/dev/null; echo "$schedule_time $backup_command >> $backup_log_file 2>&1") | crontab -

    echo -e "${GREEN}${CHECKMARK} Backup schedule added successfully to crontab!${NC}"
}

# === Call the function to execute ===
backup_scheduler_create