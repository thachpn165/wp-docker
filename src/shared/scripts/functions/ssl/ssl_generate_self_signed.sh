ssl_logic_gen_self() {
  local domain="$1"

  if [[ -z "$domain" ]]; then
    print_and_debug error "$ERROR_SITE_NOT_SELECTED"
    return 1
  fi

  # === Determine SSL directory ===
  local ssl_dir
  ssl_dir="${TEST_MODE:+/tmp/test_ssl_directory}"
  [[ "$TEST_MODE" != true ]] && ssl_dir="$NGINX_PROXY_DIR/ssl"

  local cert_path="$ssl_dir/$domain.crt"
  local key_path="$ssl_dir/$domain.key"

  debug_log "[SSL] Certificate path: $cert_path"
  debug_log "[SSL] Key path: $key_path"

  # === Verify site exists if not in test mode ===
  if [[ "$TEST_MODE" != true ]]; then
    if [[ ! -d "$PROJECT_DIR/sites/$domain" ]]; then
      print_and_debug error "$(printf "$ERROR_SITE_NOT_EXIST" "$domain")"
      return 1
    fi
  fi

  if [[ ! -d "$ssl_dir" ]]; then
    print_and_debug error "$(printf "$ERROR_DIRECTORY_NOT_FOUND" "$ssl_dir")"
    return 1
  fi

  print_msg step "$(printf "$STEP_SSL_REGENERATE_SELF_SIGNED" "$domain")"

  openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout "$key_path" \
    -out "$cert_path" \
    -subj "/C=VN/ST=HCM/L=HCM/O=WP-Docker/OU=Dev/CN=$domain"

  if [[ $? -eq 0 ]]; then
    print_msg success "$(printf "$SUCCESS_SSL_SELF_SIGNED_GENERATED" "$domain")"
    print_msg step "$STEP_NGINX_RELOADING"
    nginx_reload
    print_msg success "$SUCCESS_NGINX_RELOADED"
    print_msg info "$(printf "$INFO_SSL_CERT_PATH" "$cert_path")"
    print_msg info "$(printf "$INFO_SSL_KEY_PATH" "$key_path")"
  else
    print_and_debug error "$ERROR_SSL_SELF_SIGNED_GENERATE_FAILED"
    return 1
  fi
}