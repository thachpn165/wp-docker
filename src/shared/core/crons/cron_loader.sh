#!/bin/bash
# =============================================
# 🕒 System Cron Loader
# ---------------------------------------------
# This script is designed to run every 5 minutes
# and is responsible for managing all scheduled
# cron jobs in the WP Docker system.
#
# Instead of registering multiple cron jobs in OS crontab,
# this centralized loader checks and executes
# individual tasks based on their configured intervals.
#
# It supports:
# - SSL certificate renewal
# - Future backup, cleanup, monitoring tasks
#
# Usage (from crontab):
# */5 * * * * /bin/bash /path/to/project/cli/cron_loader.sh >> /path/to/logs/cron-system.log 2>&1
# =============================================

# === Auto-detect BASE_DIR & load configuration ===
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
    if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
        source "$SCRIPT_PATH/shared/config/load_config.sh"
        load_config_file
        break
    fi
    SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done

# === Load individual cron task implementations ===
safe_source "$CORE_DIR/crons/cron_letsencrypt_renew.sh"
safe_source "$CORE_DIR/crons/cron_backup.sh"
safe_source "$FUNCTIONS_DIR/php/php_get_version.sh"
# Add more source lines for other cron modules (e.g., backup, system)

mapfile -t sites < <(website_list)

# === Check and run cron job based on time interval (in minutes) ===
cron_run_general() {
    local last_file="$BASE_DIR/.cron/.$1"
    local interval="$2"
    local now_ts
    now_ts=$(date +%s)

    if ! _is_directory_exist "$BASE_DIR/.cron"; then
        print_msg info "📂 Creating cron directory: $BASE_DIR/.cron"
        mkdir -p "$BASE_DIR/.cron" || {
            print_msg error "❌ Failed to create cron directory: $BASE_DIR/.cron"
            return 1
        }
    fi

    if [[ ! -f "$last_file" ]]; then
        echo "$now_ts" >"$last_file"
        return 0
    fi

    local last_run
    last_run=$(<"$last_file")

    if ((now_ts - last_run >= interval * 60)); then
        echo "$now_ts" >"$last_file"
        return 0
    fi

    return 1
}

# 🔁 Renew SSL certificates every 12 hours
if cron_run_general "ssl_renew" 720; then
    cron_letsencrypt_renew
fi

# 🔁 Run PHP version check every 12 hours
if cron_run_general "php_get_version" 720; then
    php_get_version
fi

# 🔁 Run backup
for site in "${sites[@]}"; do
    cron_run_backup "$site"
done
