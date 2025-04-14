#!/bin/bash
#shellcheck disable=SC2207

# =====================================
# website_prompt_update_template: Prompt user to select and update outdated site template
# Behavior:
#   - Calls logic function to find outdated sites
#   - Displays list and lets user select one
#   - Calls CLI updater with selected domain
# =====================================
website_prompt_update_template() {

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

# =====================================
# website_logic_update_template: Detect websites with outdated templates
# Behavior:
#   - Compares each site's .template_version with the latest version
# Returns:
#   - List of outdated domains (printed to stdout)
# =====================================
website_logic_update_template() {
  TEMPLATE_VERSION_NEW=$(cat "$BASE_DIR/shared/templates/.template_version" 2>/dev/null || echo "unknown")

  outdated_sites=()
  if [[ -z "$domain" ]]; then
    website_prompt_update_template
  fi

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
