#!/bin/bash
# ==================================================
# File: cron_runner.sh
# Description: CLI script to manage and execute cron jobs, including Let's Encrypt renewal 
#              and PHP version retrieval.
# Functions:
#   - letsencrypt_renew: Renew Let's Encrypt certificates.
#       Parameters: None.
#       Returns: None.
#   - php_get_version: Retrieve the current PHP version.
#       Parameters: None.
#       Returns: None.
#   - all: Execute all cron jobs, including Let's Encrypt renewal and others.
#       Parameters: None.
#       Returns: None.
# ==================================================

# Auto-detect BASE_DIR & load configuration
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
    if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
        source "$SCRIPT_PATH/shared/config/load_config.sh"
        load_config_file
        break
    fi
    SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done

safe_source "$CORE_DIR/crons/cron_letsencrypt_renew.sh"
safe_source "$FUNCTIONS_DIR/php_loader.sh"

# Handle input commands
case "$1" in
letsencrypt_renew)
    cron_letsencrypt_renew
    ;;
php_get_version)
    php_get_version
    ;;
all)
    cron_letsencrypt_renew
    # Add additional cron jobs here, e.g.:
    # cron_backup_auto
    ;;
*)
    echo "⚙️  Usage: $0 {letsencrypt_renew|all}" >&2
    exit 1
    ;;
esac