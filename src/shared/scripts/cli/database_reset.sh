#!/bin/bash
# This script resets the database for a specified domain.
#
# 🔧 Auto-detects the base directory and loads the global configuration.
# 
# Usage:
#   ./database_reset.sh --domain=<domain_name>
#
# Flags:
#   --domain=<domain_name>   (Required) Specifies the domain for which the database will be reset.
#
# Behavior:
# - The script parses the command-line arguments to extract the domain name.
# - If the domain is not provided, the script exits with an error message.
# - It sources necessary configuration and function files to perform the database reset.
# - Calls the `database_reset_logic` function with the provided domain name.
#
# Error Handling:
# - Exits with an error if an unknown parameter is passed.
# - Exits with an error if the required `--domain` parameter is missing.

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

# Ensure domain is set
if [[ -z "$domain" ]]; then
    print_and_debug error "$ERROR_MISSING_PARAM: --domain"
    exit 1
fi

# Call the logic function to reset the database
database_reset_logic "$domain"