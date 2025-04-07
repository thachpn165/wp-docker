ssl_install_manual_logic() {
  local domain="$1"
  local SSL_DIR="$2"

  if [[ -z "$domain" ]]; then
    print_and_debug error "$ERROR_SITE_NOT_SELECTED"
    return 1
  fi

  local target_crt="$SSL_DIR/$domain.crt"
  local target_key="$SSL_DIR/$domain.key"

  debug_log "[SSL INSTALL MANUAL] Domain: $domain"
  debug_log "[SSL INSTALL MANUAL] CRT path: $target_crt"
  debug_log "[SSL INSTALL MANUAL] KEY path: $target_key"

  if [[ ! -s "$target_crt" || ! -s "$target_key" ]]; then
    print_and_debug error "$ERROR_SSL_FILE_EMPTY_OR_MISSING"
    return 1
  fi

  print_msg success "$SUCCESS_SSL_MANUAL_SAVED"

  print_msg step "$STEP_NGINX_RELOADING"
  nginx_reload
  print_msg success "$SUCCESS_NGINX_RELOADED"
}