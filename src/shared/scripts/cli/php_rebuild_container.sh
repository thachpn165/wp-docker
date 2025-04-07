#!/bin/bash
# This script is used to rebuild the PHP container for a specified domain.
# It auto-detects the base directory, loads global configurations, and executes
# the necessary logic to rebuild the PHP container.

# === Script Details ===

# === Functionality ===
# 1. Auto-detects the base directory of the script and loads the global configuration.
# 2. Parses command-line flags to extract the required parameters.
# 3. Validates the provided parameters to ensure correctness.
# 4. Calls the logic function to rebuild the PHP container for the specified domain.

# === Command-Line Parameters ===
# --domain=<domain_name>
#   - Required: Specifies the domain name for which the PHP container should be rebuilt.
#   - Example: --domain=example.tld

# === Error Handling ===
# - If an unknown parameter is provided, the script will display an error message
#   and an example of the correct usage, then exit with a status code of 1.
# - If the required --domain parameter is missing, the script will display an error
#   message and exit with a status code of 1.

# === Dependencies ===
# - Requires the `php_loader.sh` script to be sourced for PHP-related functions.
# - Relies on the `php_rebuild_container_logic` function to perform the rebuild operation.

# === Usage Example ===
# ./php_rebuild_container.sh --domain=example.tld


# 🔧 Auto-detect BASE_DIR and load global configuration
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
  if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
    source "$SCRIPT_PATH/shared/config/load_config.sh"
    break
  fi
  SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done
source "$FUNCTIONS_DIR/php_loader.sh"

# === Parse command line flags ===
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --domain=*)
      domain="${1#*=}"
      shift
      ;;
    *)
      #echo "Unknown parameter: $1"
      print_and_debug error "$ERROR_UNKNOW_PARAM: $1"
      print_and_debug info "$INFO_PARAM_EXAMPLE:\n  --domain=example.tld"
      exit 1
      ;;
  esac
done

# Ensure valid parameters are passed
if [[ -z "$domain" ]]; then
  #echo "${CROSSMARK} Missing --domain parameter. Please provide the site name."
  print_and_debug error "$ERROR_MISSING_PARAM: --domain"
  exit 1
fi

# Call the logic function to rebuild the PHP container
php_rebuild_container_logic "$domain"