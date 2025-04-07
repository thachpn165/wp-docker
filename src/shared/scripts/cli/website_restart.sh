# This script is used to restart a WordPress website managed by Docker Compose.
# It ensures the script is run in a Bash shell, determines the project directory,
# loads necessary configuration files, and restarts the specified website's containers.
#
# Usage:
#   ./website_restart.sh --domain=SITE_DOMAIN
#
# Arguments:
#   --domain=SITE_DOMAIN   (Required) The name of the WordPress site to restart.
#
# Script Workflow:
# 1. Verifies that the script is executed in a Bash shell.
# 2. Determines the PROJECT_DIR by locating the 'config.sh' file in the directory structure.
# 3. Loads the configuration file and required functions.
# 4. Parses the --domain argument to identify the target site.
# 5. Stops and removes the Docker containers associated with the specified site.
# 6. Restarts the Docker containers for the specified site.
#
# Exit Codes:
#   1 - General error (e.g., missing Bash shell, PROJECT_DIR not found, or missing config file).
#   2 - Missing or invalid --domain argument.
#   3 - Docker Compose operations (down/up) failed.
#
# Prerequisites:
# - Docker and Docker Compose must be installed and configured.
# - The PROJECT_DIR/shared/config/config.sh file must exist and be properly configured.
# - The SITES_DIR must contain a subdirectory for the specified site with a valid docker-compose.yml file.
#
# Example:
#   ./website_restart.sh --domain=my_wordpress_site
#
# Notes:
# - Ensure the script has executable permissions: chmod +x website_restart.sh
# - Run the script from a terminal with appropriate permissions.
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
# === Parse argument ===
for arg in "$@"; do
  case $arg in
    --domain=*) domain="${arg#*=}" ;;
  esac
done


if [[ -z "$domain" ]]; then
  #echo "${CROSSMARK} Missing required --domain parameter"
  print_and_debug error "$ERROR_MISSING_PARAM: --domain"
  print_msg info "$INFO_PARAM_EXAMPLE:\n  --domain=example.tld"
  exit 1
fi

print_msg step "$STEP_WEBSITE_RESTARTING: $domain"
run_in_dir "$SITES_DIR/$domain" docker compose down || {
  print_msg error "$ERROR_DOCKER_DOWN"
  exit 1
}
run_in_dir "$SITES_DIR/$domain" docker compose up -d || {
  print_msg error "$ERROR_DOCKER_UP"
  exit 1
}

#echo "${CHECKMARK} Website $domain has been restarted successfully."
print_msg success "$SUCCESS_WEBSITE_RESTART: $domain"
