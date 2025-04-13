#!/bin/bash
#shellcheck disable=SC1091

# =====================================
# 🧠 database_cli.sh – CLI wrapper for database actions: export, import, reset
# =====================================

# === Auto-detect BASE_DIR & load config ===
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
    if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
        source "$SCRIPT_PATH/shared/config/load_config.sh"
        break
    fi
    SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done

# === Load logic functions (optional) ===
# safe_source "$FUNCTIONS_DIR/database_loader.sh"

# =====================================
# 📤 database_cli_export – Export WordPress database to SQL file
# Parameters:
#   --domain=<domain>
#   [--save_location=<path>] (optional)
# =====================================
database_cli_export() {
    local domain save_location
    local timestamp
    timestamp=$(date +%s)

    domain=$(_parse_params "--domain" "$@")
    save_location=$(_parse_params "--save_location" "$@")

    if [[ -z "$domain" ]]; then
        print_and_debug error "$ERROR_MISSING_PARAM: --domain"
        exit 1
    fi

    # Default save path if not specified
    if [[ -z "$save_location" ]]; then
        save_location="${SITES_DIR}/$domain/backups/${domain}-backup-$(date +%F)-$timestamp.sql"
    fi

    database_export_logic "$domain" "$save_location"
}

# =====================================
# 📥 database_cli_import – Import SQL file into WordPress database
# Parameters:
#   --domain=<domain>
#   --backup_file=<path>
# =====================================
database_cli_import() {
    local domain backup_file

    domain=$(_parse_params "--domain" "$@")
    backup_file=$(_parse_params "--backup_file" "$@")

    if [[ -z "$domain" || -z "$backup_file" ]]; then
        print_and_debug error "$ERROR_MISSING_PARAM: --domain & --backup_file"
        exit 1
    fi

    debug_log "Domain: $domain"
    debug_log "Backup file: $backup_file"

    database_import_logic "$domain" "$backup_file"
}

# =====================================
# ♻️ database_cli_reset – Drop and re-create WordPress database
# Parameters:
#   --domain=<domain>
# =====================================
database_cli_reset() {
    local domain
    domain=$(_parse_params "--domain" "$@")

    if [[ -z "$domain" ]]; then
        print_and_debug error "$ERROR_MISSING_PARAM: --domain"
        exit 1
    fi

    database_logic_reset "$domain"
}
