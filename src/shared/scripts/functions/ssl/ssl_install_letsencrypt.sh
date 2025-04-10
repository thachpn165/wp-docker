ssl_install_lets_encrypt_logic() {
  local domain="$1"  # Lấy domain từ tham số truyền vào
  local email="$2"   # Lấy email từ tham số truyền vào
  local staging="$3" # Lấy staging từ tham số truyền vào

  if [[ -z "$domain" ]]; then
    print_and_debug error "$ERROR_MISSING_PARAM: --domain"
    return 1
  fi

  print_msg info "$(printf "$INFO_DOMAIN_SELECTED" "$domain")"
  local ssl_dir=${SSL_DIR:-"$NGINX_PROXY_DIR/ssl"}
  local webroot="$SITES_DIR/$domain/wordpress"
  if [[ ! -d "$webroot" ]]; then
    print_and_debug error "$ERROR_DIRECTORY_NOT_FOUND: $webroot"
    return 1
  fi

  # Kiểm tra nếu certbot chưa được cài đặt
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
  debug_log "[SSL] Running certbot for domain: $domain with webroot: $webroot"
  
  # Kiểm tra nếu tham số $staging có giá trị true thì thêm --staging vào lệnh certbot
  local certbot_cmd="certbot certonly --webroot -w $webroot -d $domain --non-interactive --agree-tos -m $email"
  if [[ "$staging" == "true" ]]; then
    certbot_cmd="$certbot_cmd --staging"
  fi

  # Thực thi lệnh certbot
  eval "$certbot_cmd"

  # Đường dẫn đến chứng chỉ và khóa
  local CERT_PATH="/etc/letsencrypt/live/$domain/fullchain.pem"
  local KEY_PATH="/etc/letsencrypt/live/$domain/privkey.pem"

  if [[ ! -f "$CERT_PATH" || ! -f "$KEY_PATH" ]]; then
    print_and_debug error "$(printf "$ERROR_SSL_CERT_NOT_FOUND" "$domain")"
    return 1
  fi

  print_msg success "$SUCCESS_SSL_LETS_ENCRYPT_ISSUED: $domain"

  # Debug log thư mục đích nơi chứng chỉ sẽ được sao chép
  debug_log "[SSL] Copying certificate to directory: $ssl_dir"

  # Kiểm tra thư mục và copy chứng chỉ vào thư mục SSL
  is_directory_exist "$ssl_dir"
  run_cmd "sudo chown -R $USER:$USER $ssl_dir"
  copy_file "$CERT_PATH" "$ssl_dir/$domain.crt"
  copy_file "$KEY_PATH" "$ssl_dir/$domain.key"

  # Debug log để xác nhận việc sao chép thành công
  debug_log "[SSL] Certificate copied successfully: $ssl_dir/$domain.crt and $ssl_dir/$domain.key"

  print_msg step "$STEP_NGINX_RELOADING"
  nginx_reload

  print_msg success "$(printf "$SUCCESS_SSL_INSTALLED" "$domain")"
}