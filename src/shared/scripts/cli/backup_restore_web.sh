#!/bin/bash
# This script is used to restore a website from backup files. It supports restoring both code and database backups.
#
# 🔧 Auto-detects the base directory and loads global configuration files.
#
# === Command Line Flags ===
# --domain=<domain_name>
#   (Required) The domain name of the website to restore. Example: --domain=example.tld
#
# --code_backup_file=<path_to_code_backup>
#   (Optional) The file path to the code backup archive (e.g., .tar.gz). Example: --code_backup_file=/path/to/code_backup.tar.gz
#
# --db_backup_file=<path_to_db_backup>
#   (Optional) The file path to the database backup file (e.g., .sql). Example: --db_backup_file=/path/to/db_backup.sql
#
# --test_mode=<true|false>
#   (Optional) A flag to indicate whether to run the script in test mode. Example: --test_mode=true
#
# === Behavior ===
# - The script ensures that the `--domain` parameter is provided. If missing, it will display an error and exit.
# - If provided, the script will call the `backup_restore_web_logic` function, passing the domain, code backup file, 
#   database backup file, and test mode as arguments.
#
# === Error Handling ===
# - If an unknown parameter is passed, the script will display an error message with examples of valid parameters.
# - If the required `--domain` parameter is missing, the script will display an error message and exit.
#
# === Dependencies ===
# - Requires `load_config.sh` to load global configurations.
# - Requires `backup_loader.sh` for backup-related functions.
#
# === Example Usage ===
# ./backup_restore_web.sh --domain=example.tld --code_backup_file=/path/to/code_backup.tar.gz --db_backup_file=/path/to/db_backup.sql --test_mode=true

# 🔧 Auto-detect BASE_DIR and load global configuration
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
  if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
    source "$SCRIPT_PATH/shared/config/load_config.sh"
    break
  fi
  SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done
source "$FUNCTIONS_DIR/backup_loader.sh"

# === Parse command line flags ===
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --domain=*)
      domain="${1#*=}"
      shift
      ;;
    --code_backup_file=*)
      code_backup_file="${1#*=}"
      shift
      ;;
    --db_backup_file=*)
      db_backup_file="${1#*=}"
      shift
      ;;
    --test_mode=*)
      test_mode="${1#*=}"
      shift
      ;;
    *)
      #echo "Unknown parameter: $1"
      print_and_debug error "$ERROR_UNKNOW_PARAM: $1"
      print_and_debug info "$INFO_PARAM_EXAMPLE:\n  --domain=example.tld\n  --code_backup_file=/path/to/code_backup.tar.gz\n  --db_backup_file=/path/to/db_backup.sql\n  --test_mode=true/false"
      exit 1
      ;;
  esac
done

# Ensure domain is passed, but code_backup_file and db_backup_file can be optional
if [[ -z "$domain" ]]; then
  #echo "${CROSSMARK} Missing site_name parameter."
  print_and_debug error "$ERROR_MISSING_PARAM: --domain"
  print_and_debug info "$INFO_PARAM_EXAMPLE:\n  --domain=example.tld\n  --code_backup_file=/path/to/code_backup.tar.gz\n  --db_backup_file=/path/to/db_backup.sql\n  --test_mode=true/false"
  exit 1
fi

# Call the logic function to restore the website, passing the necessary parameters
backup_restore_web_logic "$domain" "$code_backup_file" "$db_backup_file" "$test_mode"