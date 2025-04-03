#!/bin/bash

# Load config & website_loader.sh
if [[ -z "$PROJECT_DIR" ]]; then
  SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
  while [[ "$SCRIPT_PATH" != "/" ]]; do
    if [[ -f "$SCRIPT_PATH/shared/config/config.sh" ]]; then
      PROJECT_DIR="$SCRIPT_PATH"
      break
    fi
    SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
  done
fi

CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "${CROSSMARK} Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi
source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/website_loader.sh"

# === Get the outdated sites list from the logic ===
outdated_sites=($(website_management_update_site_template_logic))

# Check if there are any outdated sites
if [[ ${#outdated_sites[@]} -eq 0 ]]; then
  echo -e "${YELLOW}${WARNING} No outdated sites found.${NC}"
  exit 1
fi

# Display the list of websites needing update
echo -e "${CYAN}🔧 List of sites needing update:${NC}"
for site in "${outdated_sites[@]}"; do
  echo "  $site"
done

# Ask the user if they want to update any of the sites
SELECTED_SITE=$(select_from_list "🔹 Select a website to update:" "${outdated_sites[@]}")
if [[ -z "$SELECTED_SITE" ]]; then
  echo -e "${RED}${CROSSMARK} Invalid selection!${NC}"
  exit 1
fi

# Proceed with update
echo -e "${GREEN}${CHECKMARK} Updating website '$SELECTED_SITE'...${NC}"
bash "$SCRIPTS_DIR/cli/website_update_template.sh" --domain="$SELECTED_SITE"