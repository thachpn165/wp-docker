#!/bin/bash
# ==================================================
# File: website_setup.sh
# Description: Functions to set up website configurations and NGINX for WordPress websites, including:
#              - Saving initial website configuration to `.config.json`.
#              - Creating NGINX configuration files for websites.
# Functions:
#   - website_set_config: Save initial website configuration to `.config.json`.
#       Parameters:
#           $1 - domain: Domain name of the website.
#           $2 - php_version: PHP version to use for the website.
#   - website_setup_nginx: Create NGINX configuration file for a selected domain.
#       Parameters:
#           $1 - domain: Domain name of the website.
# ==================================================

website_set_config() {
  # Save initial website configuration to `.config.json`.
  # Parameters:
  #   $1 - domain: Domain name of the website.
  #   $2 - php_version: PHP version to use for the website.

  local domain="$1"
  local php_version="$2"

  if [[ -z "$domain" || -z "$php_version" ]]; then
    print_msg error "❌ Missing parameters in website_set_config()"
    print_msg info "Usage: website_set_config <domain> <php_version>"
    return 1
  fi
  _is_valid_domain "$domain" || return 1

  # Save config to `.config.json` using `json_set_site_value`.
  json_set_site_value "$domain" "DOMAIN" "$domain"
  json_set_site_value "$domain" "PHP_VERSION" "$php_version"
  json_set_site_value "$domain" "CONTAINER_PHP" "${domain}${PHP_CONTAINER_SUFFIX}"

  # Create database information for the website.
  local db_name db_user db_pass
  db_name="wpdb"
  db_user="wpusr"
  db_pass="$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 18)"

  mysql_logic_create_db_name "$domain" "$db_name" || return 1
  mysql_logic_create_db_user "$domain" "$db_user" "$db_pass" || return 1

  local final_db_name final_db_user
  final_db_name="$(json_get_site_value "$domain" "db_name")"
  final_db_user="$(json_get_site_value "$domain" "db_user")"
  mysql_logic_grant_all_privileges "$final_db_name" "$final_db_user"

  # Debug output.
  debug_log "[website_set_config] CONTAINER_PHP=${domain}${PHP_CONTAINER_SUFFIX}" 
  debug_log "[website_set_config] DOMAIN=$domain"
  debug_log "[website_set_config] PHP_VERSION=$php_version"
}

website_setup_nginx() {
  # Create NGINX configuration file for a selected domain.
  # Parameters:
  #   $1 - domain: Domain name of the website.

  # Define paths.
  NGINX_CONF_DIR="$NGINX_PROXY_DIR/conf.d"
  NGINX_TEMPLATE="$TEMPLATES_DIR/nginx-proxy.conf.template"

  # Assign a value to the domain variable.
  domain=${1:-default_domain}

  NGINX_CONF="$NGINX_CONF_DIR/$domain.conf"

  # Check if target directory exists.
  _is_directory_exist "$NGINX_CONF_DIR" >/dev/null 2>&1

  # Remove existing config file if it exists.
  if _is_file_exist "$NGINX_CONF" >/dev/null 2>&1; then
    debug_log "$WARNING_REMOVE_OLD_NGINX_CONF: $NGINX_CONF"
    rm -f "$NGINX_CONF"
  fi

  # Check and copy template.
  if _is_file_exist "$NGINX_TEMPLATE"; then
    if [[ ! -d "$(dirname "$NGINX_TEMPLATE")" ]]; then
      debug_log "$ERROR_NGINX_TEMPLATE_DIR_MISSING: $(dirname "$NGINX_TEMPLATE")"
      exit 1
    fi

    copy_file "$NGINX_TEMPLATE" "$NGINX_CONF" >/dev/null 2>&1
    sedi "s|\\\${DOMAIN}|$domain|g" "$NGINX_CONF"
    php_container=$(json_get_site_value "$domain" "CONTAINER_PHP")
    sedi "s|\\\${PHP_CONTAINER}|$php_container|g" "$NGINX_CONF"

    print_and_debug success "$SUCCESS_NGINX_CONF_CREATED: $NGINX_CONF"
  else
    print_and_debug error "$ERROR_NGINX_TEMPLATE_NOT_FOUND: $NGINX_TEMPLATE"
    exit 1
  fi
}