#!/bin/bash
if [ -z "$BASH_VERSION" ]; then
  echo "❌ This script must be run in a Bash shell." >&2
  exit 1
fi

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
    echo "❌ Unable to determine PROJECT_DIR. Please check the script's directory structure." >&2
    exit 1
  fi
fi

# Load the config file if PROJECT_DIR is set
CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi

# Source the config file
source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/php_loader.sh"

# === Select Website ===
select_website || exit 1  # Use the existing select_website function to allow user to select a site

# === Confirm Rebuild PHP Container ===
echo -e "${YELLOW}🔁 Rebuild the PHP container for site: $SITE_NAME${NC}"
read -p "Are you sure you want to rebuild the PHP container for this site? (y/n): " confirm_rebuild
confirm_rebuild=$(echo "$confirm_rebuild" | tr '[:upper:]' '[:lower:]')

if [[ "$confirm_rebuild" != "y" ]]; then
  echo -e "${RED}❌ Operation canceled. No changes made.${NC}"
  exit 1
fi

# === Call the CLI to rebuild PHP container ===
bash "$CLI_DIR/php_rebuild_container.sh" --site_name="$SITE_NAME"