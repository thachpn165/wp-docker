#!/bin/bash

# ==============================
# WordPress Setup & Utilities
# ==============================

wp_set_wpconfig() {
  local container_php="$1"
  local db_name="$2"
  local db_user="$3"
  local db_pass="$4"
  local container_db="$5"

  print_msg info "$INFO_WP_CONFIGURING"

  docker exec -i "$container_php" sh -c "
    cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php && \
    sed -i 's/database_name_here/$db_name/' /var/www/html/wp-config.php && \
    sed -i 's/username_here/$db_user/' /var/www/html/wp-config.php && \
    sed -i 's/password_here/$db_pass/' /var/www/html/wp-config.php && \
    sed -i 's/localhost/$container_db/' /var/www/html/wp-config.php && \
    cat <<'EOF' | tee -a /var/www/html/wp-config.php

if (isset(\$_SERVER['HTTP_X_FORWARDED_PROTO']) && strpos(\$_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false) {
    \$_SERVER['HTTPS'] = 'on';
}
EOF
  "

  if [[ $? -eq 0 ]]; then
    print_msg success "$SUCCESS_WP_CONFIG_DONE"
  else
    print_and_debug error "$ERROR_WP_CONFIG_FAILED"
    exit 1
  fi
}

wp_install() {
  local domain="$1"
  local site_url="$2"
  local title="$3"
  local admin_user="$4"
  local admin_pass="$5"
  local admin_email="$6"

  print_msg info "$INFO_WP_INSTALLING"
  bash "$CLI_DIR/wordpress_wp_cli.sh" --domain="$domain" -- core install \
    --url="$site_url" --title="$title" \
    --admin_user="$admin_user" --admin_password="$admin_pass" --admin_email="$admin_email"
  exit_if_error "$?" "$ERROR_WP_INSTALL_FAILED"
  print_msg success "$SUCCESS_WP_INSTALLED"
}

wp_set_permalinks() {
  local domain="$1"
  if [[ -z "$domain" ]]; then
    print_and_debug error "❌ Missing domain in wp_set_permalinks()"
    return 1
  fi

  bash "$CLI_DIR/wordpress_wp_cli.sh" --domain="$domain" -- option update permalink_structure '/%postname%/'
  exit_if_error "$?" "$ERROR_WP_PERMALINK_FAILED"
}

wp_plugin_install_security_plugin() {
  local domain="$1"

  if [[ -z "$domain" ]]; then
    print_and_debug error "❌ Missing domain in wp_plugin_install_security_plugin()"
    return 1
  fi

  bash "$CLI_DIR/wordpress_wp_cli.sh" --domain="$domain" -- plugin install limit-login-attempts-reloaded --activate
  exit_if_error "$?" "$ERROR_WP_SECURITY_PLUGIN"
  print_msg success "$SUCCESS_WP_SECURITY_PLUGIN"
}

wp_plugin_install_performance_lab() {
  local domain="$1"

  if [[ -z "$domain" ]]; then
    print_and_debug error "❌ Missing domain in wp_plugin_install_performance_lab()"
    return 1
  fi

  bash "$CLI_DIR/wordpress_wp_cli.sh" --domain="$domain" -- plugin install performance-lab --activate
  exit_if_error "$?" "$ERROR_WP_PERFORMANCE_PLUGIN"
  print_msg success "$SUCCESS_WP_PERFORMANCE_PLUGIN"
}

check_and_update_wp_cli() {
  local wp_cli_path="shared/bin/wp"
  local current_version

  mkdir -p "$(dirname "$wp_cli_path")"

  if [[ -f "$wp_cli_path" ]]; then
    current_version=$("$wp_cli_path" --version 2>/dev/null | awk '{print $2}')
    print_msg info "$(printf "$INFO_WPCLI_CURRENT" "$current_version")"
    print_msg info "$INFO_WPCLI_UPDATING"
  else
    print_msg warning "$WARNING_WPCLI_NOT_FOUND"
  fi

  curl -sSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o "$wp_cli_path"
  chmod +x "$wp_cli_path"

  new_version=$("$wp_cli_path" --version 2>/dev/null | awk '{print $2}')
  print_msg success "$(printf "$SUCCESS_WPCLI_UPDATED" "$new_version")"
}
