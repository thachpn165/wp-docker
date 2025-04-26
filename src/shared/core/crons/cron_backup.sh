# This script handles the scheduled backup process for websites.
# It determines whether a backup should be triggered based on the configuration
# and the last backup timestamp. Backups can be stored locally or in the cloud.

# Function: _cron_run_backup_trigger
# Description:
#   Triggers the backup process for a specific domain and storage type.
# Parameters:
#   $1 - domain (string): The domain name of the website to back up.
#   $2 - storage (string): The type of storage for the backup (e.g., "local" or "cloud").
#   $3 - rclone_storage (string, optional): The rclone storage configuration for cloud backups.
# Returns:
#   1 if required parameters are missing, otherwise triggers the backup process.

# Function: cron_run_backup
# Description:
#   Manages the scheduled backup process for a specific site. It checks the backup
#   configuration, calculates the interval since the last backup, and triggers a new
#   backup if the interval has elapsed.
# Parameters:
#   $1 - site (string): The identifier of the site to back up.
# Returns:
#   1 if the backup is not enabled or required parameters are missing.
#   0 if a backup is successfully triggered.
safe_source "$CLI_DIR/backup_website.sh"

_cron_run_backup_trigger() {
    local domain="$1"
    local storage="$2"
    local rclone_storage="$3"

    if [[ -z "$domain" || -z "$storage" ]]; then
        print_msg error "❌ Missing required parameters for backup trigger (domain: $domain, storage: $storage)"
        return 1
    fi
    print_msg step "🚀 Running scheduled backup for $domain → $storage"

    if [[ "$storage" == "cloud" && -n "$rclone_storage" ]]; then
        backup_cli_backup_web --domain="$domain" --storage="cloud" --rclone_storage="$rclone_storage"
    else
        backup_cli_backup_web --domain="$domain" --storage="local"
    fi
}

cron_run_backup() {
    local site="$1"
    local last_file="$BASE_DIR/.cron/.backup_${site}"
    local now_ts
    now_ts=$(date +%s)

    local enabled interval_days storage rclone_storage
    enabled=$(json_get_site_value "$site" "backup_schedule.enabled")
    interval_days=$(json_get_site_value "$site" "backup_schedule.interval_days")
    storage=$(json_get_site_value "$site" "backup_schedule.storage")
    rclone_storage=$(json_get_site_value "$site" "backup_schedule.rclone_storage")

    [[ "$enabled" != "true" ]] && return 1
    [[ -z "$interval_days" || "$interval_days" -lt 1 ]] && interval_days=1
    [[ -z "$storage" ]] && print_msg warning "⚠️ Missing backup storage for $site" && return 1

    local interval_sec=$((interval_days * 86400))
    mkdir -p "$BASE_DIR/.cron"

    if [[ ! -f "$last_file" ]]; then
        echo "$now_ts" >"$last_file"
        _cron_run_backup_trigger "$site" "$storage" "$rclone_storage"
        return 0
    fi

    local last_run
    last_run=$(<"$last_file")

    if ((now_ts - last_run >= interval_sec)); then
        echo "$now_ts" >"$last_file"
        _cron_run_backup_trigger "$site" "$storage" "$rclone_storage"
        return 0
    fi

    return 1
}
