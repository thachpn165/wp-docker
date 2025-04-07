#!/bin/bash
# backup_website.sh
#
# This script is used to back up a website, supporting both local and cloud storage options.
#
# Prerequisites:
# - The script must be run in a Bash shell.
# - The environment variable PROJECT_DIR must be set or determinable from the script's directory structure.
# - A valid configuration file (config.sh) must exist in the shared/config directory.
# - The backup_loader.sh script must be available in the FUNCTIONS_DIR.
#
# Usage:
#   ./backup_website.sh --domain=example.tld --storage=<local|cloud> [--rclone_storage=<rclone_storage_name>]
#
# Parameters:
#   --domain         (Required) The name of the site to back up.
#   --storage           (Required) The storage type for the backup. Valid values are "local" or "cloud".
#   --rclone_storage    (Optional) The name of the rclone storage configuration. Required if --storage is "cloud".
#
# Behavior:
# - Validates that the script is run in a Bash shell.
# - Determines the PROJECT_DIR by searching for the config.sh file in the script's directory structure.
# - Loads the configuration file and backup loader script.
# - Parses command-line arguments to extract the site name, storage type, and optional rclone storage name.
# - Validates the provided parameters.
# - Calls the `backup_website_logic` function to perform the backup operation.
#
# Exit Codes:
# - 1: General error, such as missing dependencies, invalid parameters, or configuration issues.
#
# Examples:
#   Backup to local storage:
#     ./backup_website.sh --domain=mywebsite --storage=local
#
#   Backup to cloud storage:
#     ./backup_website.sh --domain=mywebsite --storage=cloud --rclone_storage=mycloud

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
    --storage=*)
      storage="${1#*=}"
      shift
      ;;
    --rclone_storage=*)
      rclone_storage="${1#*=}"
      shift
      ;;
    *)
      #echo "Unknown parameter: $1"
      print_and_debug error "$ERROR_UNKNOW_PARAM: $1"
      exit 1
      ;;
  esac
done

# Ensure valid parameters are passed
if [[ -z "$domain" || ( "$storage" != "local" && "$storage" != "cloud" ) ]]; then
  #echo "${CROSSMARK} Missing or invalid parameters. Ensure --domain, --storage, and --rclone_storage are correctly provided."
  print_and_debug error "$ERROR_UNKNOW_PARAM: --domain or --storage"
  print_and_debug info "$INFO_PARAM_EXAMPLE:\n  --domain=example.tld\n  --storage=local/cloud\n  --rclone_storage=<rclone_storage_name>"
  exit 1
fi

# If storage is cloud, ensure rclone_storage is provided
if [[ "$storage" == "cloud" && -z "$rclone_storage" ]]; then
  #echo "${CROSSMARK} Missing --rclone_storage for cloud storage. Please specify the storage name."
  print_and_debug error "$ERROR_MISSING_PARAM: --rclone_storage"
  print_and_debug info "$INFO_PARAM_EXAMPLE:\n  --domain=example.tld\n  --storage=cloud\n  --rclone_storage=<rclone_storage_name>"
  exit 1
fi

# Set the SITE_DOMAIN variable for the backup_website_logic
SITE_DOMAIN="$domain"

# Call the logic function to backup the website, passing the necessary parameters including site_name and rclone_storage
backup_website_logic "$domain" "$storage" "$rclone_storage"