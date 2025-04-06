#!/usr/bin/env bash
# This script generates a self-signed SSL certificate for a specified site.
#
# Prerequisites:
# - Must be executed in a Bash shell.
# - The environment variable PROJECT_DIR must be set or determinable from the script's directory structure.
# - A valid configuration file (config.sh) must exist in the shared/config directory relative to PROJECT_DIR.
# - The ssl_loader.sh script must be available in the FUNCTIONS_DIR directory.
#
# Usage:
#   ./ssl_generate_self_signed.sh --domain=SITE_DOMAIN
#
# Arguments:
#   --domain=SITE_DOMAIN  (Required) The name of the site for which the SSL certificate will be generated.
#
# Behavior:
# 1. Verifies that the script is running in a Bash shell.
# 2. Determines the PROJECT_DIR by searching upwards from the script's directory for the config.sh file.
# 3. Loads the configuration file (config.sh) and the SSL loader script (ssl_loader.sh).
# 4. Parses the --domain argument to retrieve the site name.
# 5. Calls the `ssl_generate_self_signed_logic` function to generate the SSL certificate.
#
# Error Handling:
# - Exits with an error if not run in a Bash shell.
# - Exits with an error if PROJECT_DIR cannot be determined or the config.sh file is missing.
# - Exits with an error if the --domain argument is not provided.

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

# === Parse argument ===
for arg in "$@"; do
  case $arg in
    --domain=*) domain="${arg#*=}" ;;
  esac
done

if [[ -z "$domain" ]]; then
  print_and_debug error "$ERROR_MISSING_PARAM: --domain"
  print_and_debug info "$INFO_PARAM_EXAMPLE:\n  --domain=example.tld"
  exit 1
fi

# === Generate self-signed SSL ===
ssl_generate_self_signed_logic "$domain"
