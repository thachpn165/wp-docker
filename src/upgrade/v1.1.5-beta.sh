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

# Ensure SITES_DIR is set
if [[ -z "$SITES_DIR" ]]; then
  echo "${CROSSMARK} SITES_DIR is not set. Please check your configuration." >&2
  exit 1
fi

# Function to rename directory based on domain in .env file
rename_site_to_domain() {
  local site_dir="$1"
  local site_name
  local domain

  # Extract site_name from the directory
  site_name=$(basename "$site_dir")

  # Check if .env file exists
  local env_file="$site_dir/.env"
  if [[ ! -f "$env_file" ]]; then
    echo "${CROSSMARK} No .env file found in $site_dir. Skipping..."
    return 1
  fi

  # Extract DOMAIN from the .env file
  domain=$(grep -i "^DOMAIN=" "$env_file" | cut -d '=' -f 2 | tr -d '[:space:]')

  if [[ -z "$domain" ]]; then
    echo "${CROSSMARK} DOMAIN not found in $env_file for $site_name. Skipping..."
    return 1
  fi

  # Check if the domain is already the folder name
  if [[ "$site_name" == "$domain" ]]; then
    echo "${CHECKMARK} Directory $site_name already matches domain $domain. Skipping rename."
    return 0
  fi

  # Rename the directory to match the domain
  echo "🔄 Renaming $site_name to $domain..."

  # Ensure SITES_DIR contains the site directory before renaming
  if mv "$SITES_DIR/$site_name" "$SITES_DIR/$domain"; then
    echo "${CHECKMARK} Renamed directory $site_name to $domain successfully."
  else
    echo "${CROSSMARK} Failed to rename directory $site_name to $domain."
    return 1
  fi
}

# Main upgrade process
echo "🔧 Upgrading to v1.1.5-beta... Renaming site directories to domain-based structure."

# Loop through all site directories in SITES_DIR
for site_dir in "$SITES_DIR"/*; do
  if [[ -d "$site_dir" ]]; then
    rename_site_to_domain "$site_dir"
  fi
done

echo "${CHECKMARK} Upgrade to v1.1.5-beta completed. All site directories have been checked and renamed if necessary."