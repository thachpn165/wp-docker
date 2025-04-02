#!/bin/bash
if [ -z "$BASH_VERSION" ]; then
  echo "${CROSSMARK} This script must be run in a Bash shell." >&2
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
source "$FUNCTIONS_DIR/php_loader.sh"

# === Select Website ===
echo -e "${YELLOW}🔧 Choose the website to change PHP version:${NC}"
select_website || exit 1

# === Prompt for PHP version ===
echo -e "${YELLOW}🔧 Select PHP version for $SITE_NAME:${NC}"
php_choose_version "$SITE_NAME"

# === Handle PHP version change logic ===
if [[ -n "$REPLY" ]]; then
    php_version="$REPLY"  # Assign the selected PHP version to php_version variable
    echo -e "${GREEN}${CHECKMARK} PHP version for $SITE_NAME has been updated to $php_version.${NC}"

    # === Send command to CLI ===
    bash "$CLI_DIR/php_change_version.sh" --site_name="$SITE_NAME" --php_version="$php_version"
else
    echo -e "${RED}${CROSSMARK} Failed to select PHP version for $SITE_NAME.${NC}"
    exit 1
fi