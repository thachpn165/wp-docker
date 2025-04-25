#!/bin/bash

# ==============================
# WordPress Setup & Utilities
# ==============================

# =====================================
# wp_set_wpconfig: Generate wp-config.php with DB credentials and HTTPS fix
# Parameters:
#   $1 - PHP container name
#   $2 - DB name
#   $3 - DB user
#   $4 - DB password
# =====================================
wp_set_wpconfig() {
  local container_php="$1"
  local db_name="$2"
  local db_user="$3"
  local db_pass="$4"
  local container_db="$MYSQL_CONTAINER_NAME"

  print_msg info "$INFO_WP_CONFIGURING"

  # ✅ Kiểm tra container có đang chạy
  if ! _is_container_running "$container_php"; then
    print_and_debug error "$(printf "$ERROR_DOCKER_CONTAINER_NOT_RUNNING" "$container_php")"
    return 1
  fi

  # ✅ Kiểm tra file wp-config-sample.php có tồn tại không
  if ! docker exec "$container_php" test -f /var/www/html/wp-config-sample.php; then
    print_and_debug error "$MSG_NOT_FOUND: /var/www/html/wp-config-sample.php"
    return 1
  fi

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
  " >/dev/null 2>&1

  if [[ $? -eq 0 ]]; then
    print_msg success "$SUCCESS_WP_CONFIG_DONE"
  else
    print_and_debug error "$ERROR_WP_CONFIG_FAILED"
    return 1
  fi
}

# =====================================
# wp_install: Install WordPress core using WP-CLI
# Parameters:
#   $1 - domain
#   $2 - site URL
#   $3 - site title
#   $4 - admin username
#   $5 - admin password
#   $6 - admin email
# =====================================
wp_install() {
  local domain="$1"
  local site_url="$2"
  local title="$3"
  local admin_user="$4"
  local admin_pass="$5"
  local admin_email="$6"
  _is_valid_domain "$domain" || return 1
  _is_valid_email "$admin_email" || return 1
  print_msg info "$INFO_WP_INSTALLING"
  bash "$CLI_DIR/wordpress_wp_cli.sh" --domain="$domain" -- core install \
    --url="$site_url" --title="$title" \
    --admin_user="$admin_user" --admin_password="$admin_pass" --admin_email="$admin_email" --skip-email >/dev/null 2>&1
  exit_if_error "$?" "$ERROR_WP_INSTALL_FAILED"
  print_msg success "$SUCCESS_WP_INSTALLED"
}

# =====================================
# wp_set_permalinks: Update WordPress permalink structure
# Parameters:
#   $1 - domain
# =====================================
wp_set_permalinks() {
  local domain="$1"
  if [[ -z "$domain" ]]; then
    print_and_debug error "❌ Missing domain in wp_set_permalinks()"
    return 1
  fi

  bash "$CLI_DIR/wordpress_wp_cli.sh" --domain="$domain" -- option update permalink_structure '/%postname%/' >/dev/null 2>&1
  exit_if_error "$?" "$ERROR_WP_PERMALINK_FAILED"
}

# =====================================
# wp_plugin_install_security_plugin: Install and activate security plugin
# Parameters:
#   $1 - domain
# =====================================
wp_plugin_install_security_plugin() {
  local domain="$1"

  if [[ -z "$domain" ]]; then
    print_and_debug error "❌ Missing domain in wp_plugin_install_security_plugin()"
    return 1
  fi

  bash "$CLI_DIR/wordpress_wp_cli.sh" --domain="$domain" -- plugin install limit-login-attempts-reloaded --activate >/dev/null 2>&1
  exit_if_error "$?" "$ERROR_WP_SECURITY_PLUGIN"
  print_msg success "$SUCCESS_WP_SECURITY_PLUGIN"
}

# =====================================
# wp_plugin_install_performance_lab: Install and activate performance plugin
# Parameters:
#   $1 - domain
# =====================================
wp_plugin_install_performance_lab() {
  local domain="$1"

  if [[ -z "$domain" ]]; then
    print_and_debug error "❌ Missing domain in wp_plugin_install_performance_lab()"
    return 1
  fi

  bash "$CLI_DIR/wordpress_wp_cli.sh" --domain="$domain" -- plugin install performance-lab --activate >/dev/null 2>&1
  exit_if_error "$?" "$ERROR_WP_PERFORMANCE_PLUGIN"
  print_msg success "$SUCCESS_WP_PERFORMANCE_PLUGIN"
}

# =====================================
# check_and_update_wp_cli: Check current WP-CLI version and update if needed
# Downloads latest version to shared/bin/wp
# =====================================
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

wp_cli_install() {
  wp_cli_path="$BASE_DIR/shared/bin/wp"
  tmp_cli_path="/tmp/wp-cli.phar"

  if [[ ! -f "$wp_cli_path" ]]; then
    echo -e "$WARNING_WPCLI_NOT_FOUND"

    # Tải về thư mục tạm
    curl -fsSL -o "$tmp_cli_path" https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar ||
      exit_if_error 1 "$ERROR_WPCLI_DOWNLOAD_FAILED"

    chmod +x "$tmp_cli_path"

    # Đảm bảo thư mục đích tồn tại
    mkdir -p "$(dirname "$wp_cli_path")" ||
      exit_if_error 1 "$(printf "$ERROR_CREATE_DIR_FAILED" "$(dirname "$wp_cli_path")")"

    mv "$tmp_cli_path" "$wp_cli_path" ||
      exit_if_error 1 "$ERROR_WPCLI_MOVE_FAILED"

    echo -e "$SUCCESS_WPCLI_INSTALLED"
  else
    echo -e "$(printf "$SUCCESS_WPCLI_EXISTS" "$wp_cli_path")"
  fi
}
