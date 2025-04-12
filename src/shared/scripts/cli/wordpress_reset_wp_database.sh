#!/bin/bash
# This script resets the WordPress database for a specified site.
#
# Prerequisites:
# - The script must be executed in a Bash shell.
# - The environment variable `PROJECT_DIR` must be set or determinable from the script's directory structure.
# - The configuration file `config.sh` must exist in the `shared/config` directory within the project structure.
# - The `wordpress_loader.sh` script must be available in the directory specified by the `FUNCTIONS_DIR` variable.
#
# Usage:
#   ./wordpress_reset_wp_database.sh --domain=example.tld
#
# Parameters:
#   --domain=example.tld : (Required) The name of the WordPress site whose database will be reset.
#
# Behavior:
# - Validates that the script is run in a Bash shell.
# - Determines the `PROJECT_DIR` by searching for the `config.sh` file in the script's directory hierarchy.
# - Sources the `config.sh` configuration file and the `wordpress_loader.sh` script.
# - Parses the `--domain` parameter from the command line arguments.
# - Calls the `wordpress_reset_wp_database_logic` function to reset the database for the specified site.
#
# Error Handling:
# - Exits with an error message if the script is not run in a Bash shell.
# - Exits with an error message if `PROJECT_DIR` cannot be determined.
# - Exits with an error message if the `config.sh` file is missing.
# - Exits with an error message if the required `--domain` parameter is not provided.
# - Exits with an error message for unknown command-line parameters.

# ✅ Load configuration from any directory
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
SEARCH_PATH="$SCRIPT_PATH"
while [[ "$SEARCH_PATH" != "/" ]]; do
  if [[ -f "$SEARCH_PATH/shared/config/load_config.sh" ]]; then
    source "$SEARCH_PATH/shared/config/load_config.sh"
    load_config_file
    break
  fi
  SEARCH_PATH="$(dirname "$SEARCH_PATH")"
done

# Load functions for website management
safe_source "$FUNCTIONS_DIR/wordpress_loader.sh"

# === Parse command line flags ===
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --domain=*)
      domain="${1#*=}"
      shift
      ;;
    *)
      print_and_debug error "$ERROR_UNKNOW_PARAM: $1"
      exit 1
      ;;
  esac
done

# Ensure valid parameters are passed
if [ -z "$domain" ]; then
  print_and_debug error "$ERROR_MISSING_PARAM: --domain"
  exit 1
fi

# === Call the logic function to reset WordPress database ===
wordpress_reset_wp_database_logic "$domain"
