ssl_install_lets_encrypt_logic() {
  local ENV_FILE="$SITES_DIR/$domain/.env"
  if [[ ! -f "$ENV_FILE" ]]; then
    print_and_debug error "$ERROR_ENV_NOT_FOUND: $ENV_FILE"
    return 1
  fi

  local DOMAIN
  DOMAIN=$(fetch_env_variable "$ENV_FILE" "DOMAIN")

  if [[ -z "$DOMAIN" ]]; then
    print_and_debug error "$ERROR_ENV_DOMAIN_NOT_FOUND"
    debug_log "$INFO_ENV_FILE_CONTENT"
    run_cmd cat "$ENV_FILE"
    return 1
  fi

  print_msg info "$(printf "$INFO_DOMAIN_SELECTED" "$DOMAIN")"

  local WEBROOT="$SITES_DIR/$domain/wordpress"
  if [[ ! -d "$WEBROOT" ]]; then
    print_and_debug error "$ERROR_DIRECTORY_NOT_FOUND: $WEBROOT"
    return 1
  fi

if ! command -v certbot &> /dev/null; then
  print_msg warning "$WARNING_CERTBOT_NOT_INSTALLED"
  if [[ "$(uname -s)" == "Linux" ]]; then
    if [[ -f /etc/debian_version ]]; then
      apt update && apt install -y certbot
    elif [[ -f /etc/redhat-release || -f /etc/centos-release ]]; then
      yum install epel-release -y && yum install -y certbot
    else
      debug_log "⚠️ Unsupported Linux distribution: $(cat /etc/*release 2>/dev/null || echo 'unknown')"
      print_and_debug error "$ERROR_CERTBOT_INSTALL_UNSUPPORTED_OS"
      return 1
    fi
  else
    debug_log "⚠️ Unsupported OS: $(uname -s)"
    print_and_debug error "$ERROR_CERTBOT_INSTALL_MAC"
    return 1
  fi
fi

  print_msg step "$STEP_REQUEST_CERT_WEBROOT"
  debug_log "[SSL] Running certbot for domain: $DOMAIN with webroot: $WEBROOT"
  certbot certonly --webroot -w "$WEBROOT" -d "$DOMAIN" --non-interactive --agree-tos -m "admin@$DOMAIN"

  local CERT_PATH="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
  local KEY_PATH="/etc/letsencrypt/live/$DOMAIN/privkey.pem"

  if [[ ! -f "$CERT_PATH" || ! -f "$KEY_PATH" ]]; then
    print_and_debug error "$(printf "$ERROR_SSL_CERT_NOT_FOUND" "$DOMAIN")"
    return 1
  fi

  print_msg success "$SUCCESS_SSL_LETS_ENCRYPT_ISSUED"

  mkdir -p "$SSL_DIR"
  cp "$CERT_PATH" "$SSL_DIR/$DOMAIN.crt"
  cp "$KEY_PATH" "$SSL_DIR/$DOMAIN.key"

  print_msg step "$STEP_NGINX_RELOADING"
  nginx_reload

  print_msg success "$(printf "$SUCCESS_SSL_INSTALLED" "$DOMAIN")"
}
