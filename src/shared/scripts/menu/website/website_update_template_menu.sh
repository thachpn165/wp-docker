#!/bin/bash

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
safe_source "$FUNCTIONS_DIR/website_loader.sh"

# === Get the outdated sites list from the logic ===
#shellcheck disable=SC2207
outdated_sites=($(website_logic_update_template))

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