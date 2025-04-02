# This script is used to restart a WordPress website managed by Docker Compose.
# It ensures the script is run in a Bash shell, determines the project directory,
# loads necessary configuration files, and restarts the specified website's containers.
#
# Usage:
#   ./website_restart.sh --site_name=SITE_NAME
#
# Arguments:
#   --site_name=SITE_NAME   (Required) The name of the WordPress site to restart.
#
# Script Workflow:
# 1. Verifies that the script is executed in a Bash shell.
# 2. Determines the PROJECT_DIR by locating the 'config.sh' file in the directory structure.
# 3. Loads the configuration file and required functions.
# 4. Parses the --site_name argument to identify the target site.
# 5. Stops and removes the Docker containers associated with the specified site.
# 6. Restarts the Docker containers for the specified site.
#
# Exit Codes:
#   1 - General error (e.g., missing Bash shell, PROJECT_DIR not found, or missing config file).
#   2 - Missing or invalid --site_name argument.
#   3 - Docker Compose operations (down/up) failed.
#
# Prerequisites:
# - Docker and Docker Compose must be installed and configured.
# - The PROJECT_DIR/shared/config/config.sh file must exist and be properly configured.
# - The SITES_DIR must contain a subdirectory for the specified site with a valid docker-compose.yml file.
#
# Example:
#   ./website_restart.sh --site_name=my_wordpress_site
#
# Notes:
# - Ensure the script has executable permissions: chmod +x website_restart.sh
# - Run the script from a terminal with appropriate permissions.
#!/usr/bin/env bash

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
    echo "${CROSSMARK} Unable to determine PROJECT_DIR. Please check the script's directory structure." >&2
    exit 1
  fi
fi

# Load the config file if PROJECT_DIR is set
CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "${CROSSMARK} Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi

# Source the config file
source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/website_loader.sh"

# === Parse argument ===
for arg in "$@"; do
  case $arg in
    --site_name=*) SITE_NAME="${arg#*=}" ;;
  esac
done

if [[ -z "$SITE_NAME" ]]; then
  echo "${CROSSMARK} Missing required --site_name=SITE_NAME parameter"
  exit 1
fi

# === Restart Website Logic ===
echo "🔄 Restarting WordPress website: $SITE_NAME"

# Stop and remove containers related to the site
docker compose -f "$SITES_DIR/$SITE_NAME/docker-compose.yml" down || {
  echo "${CROSSMARK} Failed to stop containers for $SITE_NAME"
  exit 1
}

# Restart containers
docker compose -f "$SITES_DIR/$SITE_NAME/docker-compose.yml" up -d || {
  echo "${CROSSMARK} Failed to restart containers for $SITE_NAME"
  exit 1
}

echo "${CHECKMARK} Website $SITE_NAME has been restarted successfully."
