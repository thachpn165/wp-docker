#!/bin/bash
# ==================================================
# File: database_actions.sh
# Description: CLI wrapper for database actions, including exporting, importing, 
#              and resetting WordPress databases.
# Functions:
#   - database_cli_export: Export WordPress database to an SQL file.
#       Parameters:
#           --domain=<domain>: The domain name of the website.
#           [--save_location=<path>]: Optional path to save the exported SQL file.
#       Returns: 0 if successful, 1 otherwise.
#   - database_cli_import: Import an SQL file into a WordPress database.
#       Parameters:
#           --domain=<domain>: The domain name of the website.
#           --backup_file=<path>: Path to the SQL file to import.
#       Returns: 0 if successful, 1 otherwise.
#   - database_cli_reset: Drop and re-create a WordPress database.
#       Parameters:
#           --domain=<domain>: The domain name of the website.
#       Returns: 0 if successful, 1 otherwise.
# ==================================================

# Auto-detect BASE_DIR & load config
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
    if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
        source "$SCRIPT_PATH/shared/config/load_config.sh"
        break
    fi
    SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done

# Load logic functions
safe_source "$FUNCTIONS_DIR/database_loader.sh"

database_cli_export() {
    local domain save_location
    local timestamp
    timestamp=$(date +%s)

    domain=$(_parse_params "--domain" "$@")
    save_location=$(_parse_params "--save_location" "$@")

    _is_missing_param "$domain" "--domain" || return 1
    _is_valid_domain "$domain" || return 1

    # Default save path if not specified
    if [[ -z "$save_location" ]]; then
        save_location="${SITES_DIR}/$domain/backups/${domain}-backup-$(date +%F)-$timestamp.sql"
    fi

    database_export_logic "$domain" "$save_location"
}

database_cli_import() {
    local domain backup_file

    domain=$(_parse_params "--domain" "$@")
    backup_file=$(_parse_params "--backup_file" "$@")

    _is_missing_param "$domain" "--domain" || return 1
    _is_missing_param "$backup_file" "--backup_file" || return 1
    _is_valid_domain "$domain" || return 1

    database_import_logic "$domain" "$backup_file"
}

database_cli_reset() {
    local domain
    domain=$(_parse_params "--domain" "$@")

    _is_missing_param "$domain" "--domain" || return 1
    _is_valid_domain "$domain" || return 1

    database_logic_reset "$domain"
}