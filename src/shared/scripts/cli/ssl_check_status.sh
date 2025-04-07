#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Script Name: ssl_check_status.sh
# Description: This script checks the SSL certificate status for a given site.
#              It ensures the script is run in a Bash shell, determines the
#              project directory, loads necessary configurations, and validates
#              SSL certificates using a logic function.
#
# Usage:
#   ./ssl_check_status.sh --domain=example.tld [--ssl_dir=<ssl_directory>]
#
# Arguments:
#   --domain   (Required) The name of the site for which to check the SSL status.
#   --ssl_dir     (Optional) The directory containing SSL certificates. Defaults
#                 to "$PROJECT_DIR/shared/ssl" if not provided.
#
# Requirements:
#   - The script must be executed in a Bash shell.
#   - The environment variable PROJECT_DIR must be set, or the script must be
#     located within a directory structure containing 'shared/config/config.sh'.
#   - The configuration file 'config.sh' must exist in the expected location.
#   - The 'ssl_loader.sh' script must be available in the FUNCTIONS_DIR.
#
# Exit Codes:
#   1 - If the script is not run in a Bash shell.
#   1 - If PROJECT_DIR cannot be determined.
#   1 - If the configuration file is not found.
#   1 - If the required --domain parameter is missing.
#
# Example:
#   ./ssl_check_status.sh --domain=mywebsite --ssl_dir=/path/to/ssl
#
# -----------------------------------------------------------------------------

# 🔧 Auto-detect BASE_DIR and load global configuration
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
  if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
    source "$SCRIPT_PATH/shared/config/load_config.sh"
    break
  fi
  SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done
source "$FUNCTIONS_DIR/ssl_loader.sh"

# === Parse arguments ===
for arg in "$@"; do
  case $arg in
    --domain=*) domain="${arg#*=}" ;;
    --ssl_dir=*) SSL_DIR="${arg#*=}" ;;
  esac
done

# === Check if site_name is provided ===
if [[ -z "$domain" ]]; then
  #echo "${CROSSMARK} Missing required --domain parameter"
  print_and_debug error "$ERROR_MISSING_PARAM: --domain"
  exit 1
fi

# === Set default SSL_DIR if not provided ===
if [[ -z "$SSL_DIR" ]]; then
  SSL_DIR="$PROJECT_DIR/shared/ssl"
  debug_log "SSL_DIR not provided, using default: $SSL_DIR"
fi

# === Check SSL certificate status using the logic function ===
ssl_check_certificate_status_logic "$domain" "$SSL_DIR"