#!/bin/bash
# Ensure the script is executed in a Bash shell
if [ -z "$BASH_VERSION" ]; then
  echo "❌ This script must be run in a Bash shell." >&2
  exit 1
fi

# Ensure PROJECT_DIR is set and find it if necessary
if [[ -z "$PROJECT_DIR" ]]; then
  if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    echo "❌ This script is being sourced. Please execute it directly." >&2
    return 1
  fi
  SCRIPT_PATH="$(realpath "$0")"
  while [[ "$SCRIPT_PATH" != "/" ]]; do
    if [[ -f "$SCRIPT_PATH/shared/config/config.sh" ]]; then
      PROJECT_DIR="$SCRIPT_PATH"
      break
    fi
    SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
  done
fi

if [[ -z "$PROJECT_DIR" ]]; then
  echo "❌ Unable to determine PROJECT_DIR. Please check the script's directory structure." >&2
  exit 1
fi

# === Ensure config and functions paths are correct ===
CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi

source "$CONFIG_FILE"

FUNCTIONS_DIR="$PROJECT_DIR/shared/scripts/functions"
if [[ ! -d "$FUNCTIONS_DIR" ]]; then
  echo "❌ FUNCTIONS_DIR is not set or does not point to a valid directory." >&2
  exit 1
fi

# Load backup-related scripts
source "$FUNCTIONS_DIR/backup_loader.sh"

# === Parse command line flags ===
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --site_name=*)
      site_name="${1#*=}"
      shift
      ;;
    *)
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
done

# Ensure valid parameters are passed
if [ -z "$site_name" ]; then
  echo "❌ Missing required parameter: --site_name"
  exit 1
fi

# === Call the logic function to backup files ===
backup_file_logic "$site_name"
