ssl_edit_certificate_logic() {
  if [[ -z "$domain" ]]; then
    print_msg error "$ERROR_NO_WEBSITE_SELECTED"
    return 1
  fi

  local target_crt="$SSL_DIR/$domain.crt"
  local target_key="$SSL_DIR/$domain.key"

  if [[ ! -f "$target_crt" || ! -f "$target_key" ]]; then
    print_msg error "$(printf "$ERROR_SSL_CERT_NOT_FOUND_FOR_DOMAIN" "$domain")"
    return 1
  fi

  print_msg info "$(printf "$INFO_SSL_EDITING_FOR_DOMAIN" "$domain")"

  print_msg question "$(printf "$PROMPT_SSL_ENTER_NEW_CRT" "$domain")"
  read -r new_cert
  print_msg question "$(printf "$PROMPT_SSL_ENTER_NEW_KEY" "$domain")"
  read -r new_key

  echo "$new_cert" > "$target_crt"
  echo "$new_key" > "$target_key"

  print_msg success "$(printf "$SUCCESS_SSL_UPDATED_FOR_DOMAIN" "$domain")"

  print_msg info "$INFO_SSL_RELOADING_NGINX"
  nginx_reload

  print_msg success "$SUCCESS_NGINX_RELOADED"
}