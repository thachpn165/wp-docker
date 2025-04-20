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
safe_source "$FUNCTIONS_DIR/database_loader.sh"
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

    _is_missing_param "$domain" "--domain" || return 1
    _is_valid_domain "$domain" || return 1

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

    _is_missing_param "$domain" "--domain" || return 1
    _is_missing_param "$backup_file" "--backup_file" || return 1
    _is_valid_domain "$domain" || return 1
    is_file_exists "$backup_file" || return 1
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

    _is_missing_param "$domain" "--domain" || return 1
    _is_valid_domain "$domain" || return 1

    database_logic_reset "$domain"
}
