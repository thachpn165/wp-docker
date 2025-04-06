#!/bin/bash

# ============================================
# Script: backup_manage.sh
# Description:
#   This script is used to manage backups for a specified domain.
#   It supports actions such as listing and cleaning backups.
#
# Usage:
#   ./backup_manage.sh --domain=<domain_name> --action=<action> [--max_age_days=<days>]
#
# Parameters:
#   --domain=<domain_name>
#       The domain for which the backup management operation will be performed.
#       Example: --domain=example.tld
#
#   --action=<action>
#       The action to perform on the backups. Supported actions:
#         - list: List all backups for the specified domain.
#         - clean: Clean up old backups for the specified domain.
#       Example: --action=list
#
#   --max_age_days=<days> (Optional)
#       The maximum age (in days) of backups to retain when performing the "clean" action.
#       Example: --max_age_days=7
#
# Dependencies:
#   - Requires the `load_config.sh` script to load global configurations.
#   - Requires the `backup_loader.sh` script for backup-related functions.
#
# Error Handling:
#   - If unknown parameters are passed, the script will display an error message
#     and provide usage examples.
#   - If required parameters (--domain or --action) are missing, the script will
#     display an error message and exit.
#
# Example:
#   ./backup_manage.sh --domain=example.tld --action=clean --max_age_days=7
#
# ============================================

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
    --action=*)
      action="${1#*=}"
      shift
      ;;
    --max_age_days=*)
      max_age_days="${1#*=}"
      shift
      ;;
    *)
      print_and_debug error "$ERROR_UNKNOW_PARAM: $1"
      print_and_debug info "$INFO_PARAM_EXAMPLE:\n  --domain=example.tld\n  --action=list/clean\n  --max_age_days=7"
      exit 1
      ;;
  esac
done

# Ensure valid parameters are passed
if [[ -z "$domain" || -z "$action" ]]; then
  print_and_debug error "$ERROR_BACKUP_MANAGE_MISSING_PARAMS"
  print_and_debug info "$INFO_PARAM_EXAMPLE:\n  --domain=example.tld\n  --action=list/clean\n  --max_age_days=7"
  exit 1
fi

# Call the backup_manage function with the passed parameters
backup_manage "$domain" "$action" "$max_age_days"
