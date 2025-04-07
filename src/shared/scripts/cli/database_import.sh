#!/bin/bash
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

# Parse parameters
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --domain=*) domain="${1#*=}" ;;
        --backup_file=*) backup_file="${1#*=}" ;;
        #*) echo "Unknown parameter passed: $1"; exit 1 ;;
        *)
            print_and_debug error "$ERROR_UNKNOW_PARAM: $1"
            print_and_debug info "$INFO_PARAM_EXAMPLE:\n  --domain=example.tld\n  --backup_file=/path/to/backup.sql"
            exit 1
            ;;
    esac
    shift
done

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