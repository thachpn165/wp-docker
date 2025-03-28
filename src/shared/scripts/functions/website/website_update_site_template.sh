#!/bin/bash

website_update_site_template() {
  source "$BASE_DIR/shared/config/config.sh"
  TEMPLATE_VERSION_NEW=$(cat "$BASE_DIR/shared/templates/.template_version" 2>/dev/null || echo "unknown")

  echo -e "${YELLOW}🔍 Searching for sites with old templates...${NC}"
  outdated_sites=()

  for site_path in "$SITES_DIR/"*/; do
    [ -d "$site_path" ] || continue
    site_name=$(basename "$site_path")
    site_ver_file="$site_path/.template_version"
    site_template_version=$(cat "$site_ver_file" 2>/dev/null || echo "unknown")

    if [[ "$site_template_version" != "$TEMPLATE_VERSION_NEW" ]]; then
      outdated_sites+=("$site_name")
    fi
  done

  if [[ ${#outdated_sites[@]} -eq 0 ]]; then
    echo -e "${GREEN}✅ No sites using old templates.${NC}"
    return 0
  fi

  echo -e "${CYAN}🔧 List of sites needing update:${NC}"
  for i in "${!outdated_sites[@]}"; do
    echo "  [$i] ${outdated_sites[$i]}"
  done

  read -rp "👉 Enter the indices of sites you want to update (separated by spaces): " indexes
  selected_sites=()

  for idx in $indexes; do
    selected_sites+=("${outdated_sites[$idx]}")
  done

  for site in "${selected_sites[@]}"; do
    echo -e "\n${YELLOW}♻️ Updating configuration for site: $site${NC}"
    site_path="$SITES_DIR/$site"

    # Backup old files
    cp "$site_path/docker-compose.yml" "$site_path/docker-compose.yml.bak" 2>/dev/null || true
    cp "$NGINX_CONF_DIR/$site.conf" "$NGINX_CONF_DIR/$site.conf.bak" 2>/dev/null || true

    # Override docker-compose
    cp "$TEMPLATE_DIR/docker-compose.yml.template" "$site_path/docker-compose.yml"

    # Override NGINX config
    cp "$TEMPLATE_DIR/nginx-proxy.conf.template" "$NGINX_CONF_DIR/$site.conf"
    sed -i "s|__DOMAIN__|$site|g" "$NGINX_CONF_DIR/$site.conf"

    # Update version
    echo "$TEMPLATE_VERSION_NEW" > "$site_path/.template_version"

    echo -e "${GREEN}✅ Updated site '$site' to template version $TEMPLATE_VERSION_NEW${NC}"
  done

  echo -e "\n${GREEN}✨ Completed configuration update for selected sites.${NC}"
}
