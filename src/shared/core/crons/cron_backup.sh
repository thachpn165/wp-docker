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
