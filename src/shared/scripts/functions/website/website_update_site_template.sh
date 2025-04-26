#!/bin/bash
# ==================================================
# File: website_update_site_template.sh
# Description: Functions to detect and update outdated site templates for WordPress websites, including:
#              - Prompting the user to select and update outdated templates.
#              - Detecting websites with outdated templates by comparing versions.
# Functions:
#   - website_prompt_update_template: Prompt user to select and update outdated site templates.
#       Parameters: None.
#   - website_logic_update_template: Detect websites with outdated templates.
#       Parameters: None.
# ==================================================

website_prompt_update_template() {
  # Prompt user to select and update outdated site templates.
  # Parameters: None.

  # Get list of outdated site templates
  outdated_sites=($(website_logic_update_template))

  # Check if there are any sites to update
  if [[ ${#outdated_sites[@]} -eq 0 ]]; then
    echo -e "${YELLOW}${WARNING} No outdated sites found.${NC}"
    return 0  # Do not continue if there are no sites to update
  fi

  # Display list of sites needing update
  echo -e "${CYAN}🔧 List of sites needing update:${NC}"
  for site in "${outdated_sites[@]}"; do
    echo "  $site"
  done

  # Ask user to select a site to update
  SELECTED_SITE=$(select_from_list "🔹 Select a website to update:" "${outdated_sites[@]}")
  if [[ -z "$SELECTED_SITE" ]]; then
    echo -e "${RED}${CROSSMARK} Invalid selection!${NC}"
    return 1  # If the user does not select a valid site, stop
  fi

  # Proceed to update selected site
  echo -e "${GREEN}${CHECKMARK} Updating website '$SELECTED_SITE'...${NC}"
  bash "$SCRIPTS_DIR/cli/website_update_template.sh" --domain="$SELECTED_SITE"
}

website_logic_update_template() {
  # Detect websites with outdated templates.
  # Parameters: None.
  # Returns: List of outdated domains (printed to stdout).

  TEMPLATE_VERSION_NEW=$(cat "$BASE_DIR/shared/templates/.template_version" 2>/dev/null || echo "unknown")

  outdated_sites=()
  for site_path in "$SITES_DIR/"*/; do
    [ -d "$site_path" ] || continue
    domain=$(basename "$site_path")
    site_ver_file="$site_path/.template_version"
    site_template_version=$(cat "$site_ver_file" 2>/dev/null || echo "unknown")

    if [[ "$site_template_version" != "$TEMPLATE_VERSION_NEW" ]]; then
      outdated_sites+=("$domain")
    fi
  done

  if [[ ${#outdated_sites[@]} -eq 0 ]]; then
    return 1 # No outdated sites found
  fi

  echo "${outdated_sites[@]}" # Return list of outdated sites to caller
}