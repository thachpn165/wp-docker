#!/bin/bash

# =====================================
# 🐳 Create NGINX configuration file from available environment variables
# =====================================
website_setup_nginx() {
  # === Define paths ===
  NGINX_CONF_DIR="$NGINX_PROXY_DIR/conf.d"
  NGINX_TEMPLATE="$TEMPLATES_DIR/nginx-proxy.conf.template"
  NGINX_CONF="$NGINX_CONF_DIR/$domain.conf"

  # === Check if target directory exists ===
  is_directory_exist "$NGINX_CONF_DIR"

  # === Remove existing config file if exists ===
  if is_file_exist "$NGINX_CONF"; then
      print_and_debug warning "$WARNING_REMOVE_OLD_NGINX_CONF: $NGINX_CONF"
      run_cmd rm -f "$NGINX_CONF"
  fi

  # === Check and copy template ===
  if is_file_exist "$NGINX_TEMPLATE"; then
      if [[ ! -d "$(dirname "$NGINX_TEMPLATE")" ]]; then
          print_and_debug error "$ERROR_NGINX_TEMPLATE_DIR_MISSING: $(dirname "$NGINX_TEMPLATE")"
          exit 1
      fi

    run_cmd cp "$NGINX_TEMPLATE" "$NGINX_CONF" true
    run_cmd sedi "s|\${DOMAIN}|$domain|g" "$NGINX_CONF" true
    run_cmd sedi "s|\${PHP_CONTAINER}|$domain-php|g" "$NGINX_CONF" true

      print_and_debug success "$SUCCESS_NGINX_CONF_CREATED: $NGINX_CONF"
  else
      print_and_debug error "$ERROR_NGINX_TEMPLATE_NOT_FOUND: $NGINX_TEMPLATE"
      exit 1
  fi
}