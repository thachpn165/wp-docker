#!/bin/bash
# This script is used to change the PHP version for a specified domain in a Docker-based LEMP stack.
#
# 🔧 Auto-detect BASE_DIR and load global configuration:
# The script dynamically determines its base directory and sources the global configuration file
# located at `shared/config/load_config.sh`. It also loads PHP-related functions from `php_loader.sh`.
#
# === Command Line Flags ===
# The script accepts the following command-line arguments:
#   --domain=<domain_name>      : Specifies the domain name for which the PHP version should be changed.
#   --php_version=<php_version> : Specifies the target PHP version to switch to.
#
# === Usage ===
# Example usage of the script:
#   ./php_change_version.sh --domain=example.com --php_version=8.1
#
# === Validation ===
# The script validates that both `--domain` and `--php_version` parameters are provided.
# If either parameter is missing, it will print an error message and exit.
#
# === Logic ===
# After parsing and validating the input parameters, the script calls the `php_change_version_logic`
# function, passing the domain and PHP version as arguments. This function is expected to handle
# the actual logic for changing the PHP version.
#
# === Error Handling ===
# - If an unknown parameter is provided, the script will print an error message and display usage instructions.
# - If required parameters are missing, the script will print an error message and exit.

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
    --php_version=*)
      php_version="${1#*=}"
      shift
      ;;
    *)
      print_and_debug error "$ERROR_UNKNOW_PARAM: $1"
      print_and_debug info "Usage: $0 --domain=<domain_name> --php_version=<php_version>"
      exit 1
      ;;
  esac
done

# Validate parameters
if [[ -z "$domain" || -z "$php_version" ]]; then
  print_and_debug error "$ERROR_MISSING_PARAM: --domain or --php_version"
  exit 1
fi

# Call the logic function
php_change_version_logic "$domain" "$php_version"