# =============================================
# 🧩 website_set_config
# Usage: website_set_config <output_dir> <domain> <php_version>
# Ghi thông tin website vào file .config.json theo site.<domain>
# =============================================

website_set_config() {
  local domain="$1"
  local php_version="$2"

  if [[ -z "$domain" || -z "$php_version" ]]; then
    print_msg error "❌ Missing parameters in website_set_config()"
    print_msg info "Usage: website_set_config <domain> <php_version>"
    return 1
  fi

  # 🔐 Generate secure MySQL passwords
  local mysql_root_passwd
  local mysql_passwd
  mysql_root_passwd=$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9' | head -c 16)
  mysql_passwd=$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9' | head -c 16)

  # ✅ Save config to .config.json using json_set_site_value
  json_set_site_value "$domain" "DOMAIN" "$domain"
  json_set_site_value "$domain" "PHP_VERSION" "$php_version"
  json_set_site_value "$domain" "MYSQL_ROOT_PASSWORD" "$mysql_root_passwd"
  json_set_site_value "$domain" "MYSQL_DATABASE" "wordpress"
  json_set_site_value "$domain" "MYSQL_USER" "wpuser"
  json_set_site_value "$domain" "MYSQL_PASSWORD" "$mysql_passwd"
  json_set_site_value "$domain" "CONTAINER_PHP" "${domain}${PHP_CONTAINER_SUFFIX}"
  json_set_site_value "$domain" "CONTAINER_DB" "${domain}${DB_CONTAINER_SUFFIX}"

  # 🐛 Debug output
  debug_log "[website_set_config] DOMAIN=$domain"
  debug_log "[website_set_config] PHP_VERSION=$php_version"
  debug_log "[website_set_config] MYSQL_ROOT_PASSWORD=$mysql_root_passwd"
  debug_log "[website_set_config] MYSQL_PASSWORD=$mysql_passwd"
  debug_log "[website_set_config] CONTAINER_PHP=${domain}${PHP_CONTAINER_SUFFIX}"
  debug_log "[website_set_config] CONTAINER_DB=${domain}${DB_CONTAINER_SUFFIX}"

  print_msg success "✅ Website config saved to .config.json under site[\"$domain\"]"
}