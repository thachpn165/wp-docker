#!/bin/bash
# This script is used to export a database for a specific domain and save it to a specified location.
#
# 🔧 Auto-detects the base directory and loads global configuration files.
#
# Usage:
#   ./database_export.sh --domain=<domain_name> [--save_location=<path>]
#
# Parameters:
#   --domain=<domain_name>       (Required) The domain name of the site whose database is to be exported.
#   --save_location=<path>       (Optional) The file path where the exported database will be saved.
#                                If not provided, a default location will be used:
#                                ${SITES_DIR}/<domain>/backups/<domain>-backup-<date>-<timestamp>.sql
#
# Behavior:
#   - Validates the required parameters.
#   - Loads necessary configurations and functions.
#   - Exports the database for the specified domain to the specified or default save location.
#
# Dependencies:
#   - Requires `load_config.sh` for global configuration.
#   - Requires `database_loader.sh` for database-related functions.
#
# Notes:
#   - The script will terminate with an error message if required parameters are missing or invalid.
#   - The `database_export_logic` function is responsible for the actual database export process.
#
# Example:
#   ./database_export.sh --domain=example.com --save_location=/path/to/backup.sql
# 🔧 Auto-detect BASE_DIR and load global configuration
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
  if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
    source "$SCRIPT_PATH/shared/config/load_config.sh"
    break
  fi
  SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done
source "$FUNCTIONS_DIR/database_loader.sh"
timestamp=$(date +%s)
# Initial checks
if [ -z "$1" ]; then
  print_and_debug error "$ERROR_MISSING_PARAM: --domain <domain> [--save_location <path>]"

  exit 1
fi

# Parse parameters
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --domain=*) domain="${1#*=}" ;;
        --save_location=*) save_location="${1#*=}" ;;
        *) print_and_debug error "$ERROR_UNKNOW_PARAM: $1"
           print_and_debug info "$INFO_PARAM_EXAMPLE:\n  --domain=example.tld\n  --save_location=/path/to/backup.sql"
           exit 1 ;;
    esac
    shift
done

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

# Debug
debug_log "Domain: $domain"
debug_log "Save location: $save_location"

# Call the database export logic
database_export_logic "$domain" "$save_location"