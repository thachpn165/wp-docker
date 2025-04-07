#!/bin/bash
# backup_file.sh
#
# This script is used to back up files for a specified domain in a WordPress Docker LEMP stack.
#
# 🔧 Features:
# - Automatically detects the base directory and loads global configuration.
# - Parses command-line arguments to specify the domain for which the backup is to be created.
# - Loads backup-related functions from external scripts.
# - Validates input parameters and provides error messages for incorrect usage.
# - Executes the backup logic for the specified domain.
#
# 🛠 Usage:
#   ./backup_file.sh --domain=example.tld
#
# Command-line Arguments:
#   --domain=<domain>   Specifies the domain for which the backup is to be created.
#
# Error Handling:
# - If an unknown parameter is passed, the script displays an error message and an example of correct usage.
# - If the required `--domain` parameter is missing, the script exits with an error message.
#
# Dependencies:
# - Requires `load_config.sh` to load global configurations.
# - Requires `backup_loader.sh` to load backup-related functions.
#
# Notes:
# - Ensure that the `FUNCTIONS_DIR` variable is correctly set in the global configuration.
# - The script relies on the `backup_file_logic` function to perform the actual backup operation.


# 🔧 Auto-detect BASE_DIR and load global configuration
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
  if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
    source "$SCRIPT_PATH/shared/config/load_config.sh"
    break
  fi
  SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done

# Load backup-related scripts
source "$FUNCTIONS_DIR/backup_loader.sh"

# === Parse command line flags ===
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --domain=*)
      domain="${1#*=}"
      shift
      ;;
    *)
      print_and_debug error "$ERROR_UNKNOW_PARAM: $1"
      print_and_debug info "$INFO_PARAM_EXAMPLE:\n  --domain=example.tld"
      exit 1
      ;;
  esac
done

# Ensure valid parameters are passed
if [ -z "$domain" ]; then
  #print_msg error "$ERROR_MISSING_PARAM: --domain"
  print_and_debug error "$ERROR_UNKNOW_PARAM: --domain"
  print_and_debug info "$INFO_PARAM_EXAMPLE:\n  --domain=example.tld"
  exit 1
fi

# === Call the logic function to backup files ===
backup_file_logic "$domain"
