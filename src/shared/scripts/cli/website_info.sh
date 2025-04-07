# This script provides information about a specific website by utilizing the 
# `website_management_info_logic` function. It requires the `--domain` 
# parameter to specify the target website.

# Prerequisites:
# - The script must be executed in a Bash shell.
# - The environment variable `PROJECT_DIR` must either be set or determinable 
#   by locating the `config.sh` file in the directory structure.
# - The `config.sh` file must exist in the `$PROJECT_DIR/shared/config/` directory.
# - The `website_loader.sh` script must exist in the `$FUNCTIONS_DIR` directory.

# Script Workflow:
# 1. Verifies that the script is running in a Bash shell.
# 2. Attempts to determine the `PROJECT_DIR` by searching for the `config.sh` 
#    file in the directory hierarchy if `PROJECT_DIR` is not already set.
# 3. Ensures the `config.sh` file exists and sources it along with the 
#    `website_loader.sh` script.
# 4. Parses the `--domain` parameter from the command-line arguments.
# 5. Validates that the `--domain` parameter is provided.
# 6. Calls the `website_management_info_logic` function with the provided 
#    `site_name` to display the website information.

# Usage:
#   ./website_info.sh --domain=example.tld

# Parameters:
#   --domain=example.tld : (Required) The name of the website for which 
#                             information is to be displayed.

# Error Handling:
# - Exits with an error message if:
#   - The script is not run in a Bash shell.
#   - The `PROJECT_DIR` cannot be determined.
#   - The `config.sh` file is missing.
#   - An unknown parameter is provided.
#   - The `--domain` parameter is missing.
#!/usr/bin/env bash

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
source "$FUNCTIONS_DIR/website_loader.sh"

# === Parse argument for site_name ===
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --domain=*) domain="${1#*=}" ;;
    *)
      print_msg error "$ERROR_UNKNOW_PARAM: $1"
      print_msg info "$INFO_PARAM_EXAMPLE:\n  --domain=example.tld"
      exit 1
      ;;
  esac
  shift
done

# === Ensure domain is provided ===
if [[ -z "$domain" ]]; then
  #echo "${CROSSMARK} Missing required --domain parameter"
  print_msg error "$ERROR_MISSING_PARAM: --domain"
  exit 1
fi

# === Call logic to display website information ===
website_management_info_logic "$domain"
