#!/bin/bash

# === Load config & system_loader.sh ===
if [[ -z "$PROJECT_DIR" ]]; then
  SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
  while [[ "$SCRIPT_PATH" != "/" ]]; do
    if [[ -f "$SCRIPT_PATH/shared/config/config.sh" ]]; then
      PROJECT_DIR="$SCRIPT_PATH"
      break
    fi
    SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
  done
fi

CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi
source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/backup_loader.sh"

# === Parse command line flags ===
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --site_name=*)
      site_name="${1#*=}"
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
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
done

# Ensure valid parameters are passed
if [[ -z "$site_name" || ( "$storage" != "local" && "$storage" != "cloud" ) ]]; then
  echo "❌ Missing or invalid parameters. Ensure --site_name, --storage, and --rclone_storage are correctly provided."
  exit 1
fi

# If storage is cloud, ensure rclone_storage is provided
if [[ "$storage" == "cloud" && -z "$rclone_storage" ]]; then
  echo "❌ Missing --rclone_storage for cloud storage. Please specify the storage name."
  exit 1
fi

# Set the SITE_NAME variable for the backup_website_logic
SITE_NAME="$site_name"

# Call the logic function to backup the website, passing the necessary parameters including site_name and rclone_storage
backup_website_logic "$site_name" "$storage" "$rclone_storage"