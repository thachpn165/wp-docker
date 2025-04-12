#!/bin/bash
#shellcheck disable=SC1091

# 🔧 Auto-detect BASE_DIR and load global configuration
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
    if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
        source "$SCRIPT_PATH/shared/config/load_config.sh"
        break
    fi
    SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done

#safe_source "$FUNCTIONS_DIR/database_loader.sh"

database_cli_export() {
    timestamp=$(date +%s)
    local domain
    local save_location

    domain=$(_parse_params "--domain" "$@")
    save_location=$(_parse_params "--save_location" "$@")

    # Ensure save_location is set to default if not provided
    if [[ -z "$save_location" ]]; then
        save_location="${SITES_DIR}/$domain/backups/${domain}-backup-$(date +%F)-$timestamp.sql"
    fi

    # Ensure domain is set
    if [[ -z "$domain" ]]; then
        print_and_debug error "$ERROR_MISSING_PARAM: --domain"
        exit 1
    fi

    # If save_location is still not defined, set it to default value
    if [[ -z "$save_location" ]]; then
        save_location="${SITES_DIR}/$domain/backups/${domain}-backup-$(date +%F)-$timestamp.sql"
    fi

    # Call the database_export function with the passed parameters
    database_export_logic "$domain" "$save_location"
}

database_cli_import() {
    local domain
    local backup_file

    domain=$(_parse_params "--domain" "$@")
    backup_file=$(_parse_params "--backup_file" "$@")

    # Ensure domain and backup_file are provided
    if [[ -z "$domain" || -z "$backup_file" ]]; then
        #echo "${CROSSMARK} Missing required parameters: --domain or --backup_file."
        print_and_debug error "$ERROR_MISSING_PARAM: --domain & --backup_file"
        exit 1
    fi
    debug_log "Domain: $domain"
    debug_log "Backup file: $backup_file"

    # Call the logic function to import the database
    database_import_logic "$domain" "$backup_file"
}


database_cli_reset() {
    local domain

    # Parse parameters
    domain=$(_parse_params "--domain" "$@")

    # Ensure domain is set
    if [[ -z "$domain" ]]; then
        print_and_debug error "$ERROR_MISSING_PARAM: --domain"
        exit 1
    fi

    # Call the logic function to reset the database
    database_logic_reset "$domain"
}