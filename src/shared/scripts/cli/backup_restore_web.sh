# This script is used to restore a website from backup files. It ensures the script is run in a Bash shell,
# validates the required environment variables and parameters, and sources necessary configuration files
# before executing the restoration logic.

# Prerequisites:
# - The script must be executed in a Bash shell.
# - The environment variable `PROJECT_DIR` must be set or determinable from the script's directory structure.
# - The configuration file `config.sh` must exist in the `shared/config` directory relative to `PROJECT_DIR`.
# - The `backup_loader.sh` script must be available in the directory specified by the `FUNCTIONS_DIR` variable.

# Command-line Parameters:
# --site_name=<site_name>         (Required) The name of the site to restore.
# --code_backup_file=<file_path>  (Optional) Path to the code backup file.
# --db_backup_file=<file_path>    (Optional) Path to the database backup file.
# --test_mode=<true|false>        (Optional) Flag to indicate whether to run in test mode.

# Script Workflow:
# 1. Validates that the script is run in a Bash shell.
# 2. Determines the `PROJECT_DIR` by searching for the `config.sh` file in the directory hierarchy.
# 3. Sources the `config.sh` configuration file and the `backup_loader.sh` script.
# 4. Parses command-line arguments to extract parameters.
# 5. Validates that the `site_name` parameter is provided.
# 6. Calls the `backup_restore_web_logic` function with the provided parameters to perform the restoration.

# Exit Codes:
# 0  - Success.
# 1  - Failure due to missing prerequisites, invalid parameters, or errors during execution.

# Usage Example:
# ./backup_restore_web.sh --site_name=my_site --code_backup_file=/path/to/code.tar.gz --db_backup_file=/path/to/db.sql --test_mode=true
#!/bin/bash


# Ensure PROJECT_DIR is set
if [[ -z "$PROJECT_DIR" ]]; then
  SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
  
  # Iterate upwards from the current script directory to find 'config.sh'
  while [[ "$SCRIPT_PATH" != "/" ]]; do
    if [[ -f "$SCRIPT_PATH/shared/config/config.sh" ]]; then
      PROJECT_DIR="$SCRIPT_PATH"
      break
    fi
    SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
  done

  # Handle error if config file is not found
  if [[ -z "$PROJECT_DIR" ]]; then
    echo "❌ Unable to determine PROJECT_DIR. Please check the script's directory structure." >&2
    exit 1
  fi
fi

# Load the config file if PROJECT_DIR is set
CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi

# Source the config file
source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/backup_loader.sh"

# === Parse command line flags ===
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --site_name=*)
      site_name="${1#*=}"
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
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
done

# Ensure site_name is passed, but code_backup_file and db_backup_file can be optional
if [[ -z "$site_name" ]]; then
  echo "❌ Missing site_name parameter."
  exit 1
fi

# Call the logic function to restore the website, passing the necessary parameters
backup_restore_web_logic "$site_name" "$code_backup_file" "$db_backup_file" "$test_mode"