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
# Add more source lines for other cron modules (e.g., backup, system)

# === Check and run cron job based on time interval (in minutes) ===
cron_run_general() {
    local last_file="$BASE_DIR/.cron/.$1"
    local interval="$2"
    local now_ts
    now_ts=$(date +%s)

    mkdir -p "$BASE_DIR/.cron"

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

# === Define which cron jobs to run and how often ===

# 🔁 Renew SSL certificates every 12 hours
if cron_run_general "ssl_renew" 720; then
    cron_letsencrypt_renew
fi