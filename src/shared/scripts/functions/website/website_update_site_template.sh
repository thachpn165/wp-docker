#!/bin/bash

website_logic_update_template() {
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
    return 1  # No outdated sites found
  fi

  echo "${outdated_sites[@]}"  # Return list of outdated sites to caller
}