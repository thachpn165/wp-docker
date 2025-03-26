#!/bin/bash
website_update_site_template() {
  source "$BASE_DIR/shared/config/config.sh"
  TEMPLATE_VERSION_NEW=$(cat "$BASE_DIR/shared/templates/.template_version" 2>/dev/null || echo "unknown")

  echo -e "${YELLOW}🔍 Đang tìm các site có template cũ...${NC}"
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
    echo -e "${GREEN}✅ Không có site nào dùng template cũ.${NC}"
    return 0
  fi

  echo -e "${CYAN}🔧 Danh sách site cần cập nhật:${NC}"
  for i in "${!outdated_sites[@]}"; do
    echo "  [$i] ${outdated_sites[$i]}"
  done

  read -rp "👉 Nhập chỉ số site bạn muốn cập nhật (cách nhau bằng dấu cách): " indexes
  selected_sites=()

  for idx in $indexes; do
    selected_sites+=("${outdated_sites[$idx]}")
  done

  for site in "${selected_sites[@]}"; do
    echo -e "\n${YELLOW}♻️ Đang cập nhật cấu hình cho site: $site${NC}"
    site_path="$SITES_DIR/$site"

    # Backup file cũ
    cp "$site_path/docker-compose.yml" "$site_path/docker-compose.yml.bak" 2>/dev/null || true
    cp "$NGINX_CONF_DIR/$site.conf" "$NGINX_CONF_DIR/$site.conf.bak" 2>/dev/null || true

    # Ghi đè docker-compose
    cp "$TEMPLATE_DIR/docker-compose.yml.template" "$site_path/docker-compose.yml"

    # Ghi đè NGINX config
    cp "$TEMPLATE_DIR/nginx-proxy.conf.template" "$NGINX_CONF_DIR/$site.conf"
    sed -i "s|__DOMAIN__|$site|g" "$NGINX_CONF_DIR/$site.conf"

    # Cập nhật version
    echo "$TEMPLATE_VERSION_NEW" > "$site_path/.template_version"

    echo -e "${GREEN}✅ Đã cập nhật site '$site' lên template $TEMPLATE_VERSION_NEW${NC}"
  done

  echo -e "\n${GREEN}✨ Hoàn tất cập nhật cấu hình cho các site đã chọn.${NC}"
}
