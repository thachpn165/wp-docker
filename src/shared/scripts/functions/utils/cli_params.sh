# ========================================================================
# CLI Parameters Functions
# Used to parse command line arguments and options
# ========================================================================

# --domain
function website_domain_param() {
  local domain="$1"
  
  # Kiểm tra nếu domain rỗng hoặc không được truyền
  if [[ -z "$domain" ]]; then
    print_msg error "$ERROR_MISSING_PARAM: --domain"
    return 1
  fi

  # Parse tham số --domain nếu có
  for arg in "$@"; do
    case $arg in
    --domain=*) domain="${arg#*=}" ;;
    esac
  done

  # Kiểm tra lại nếu domain chưa được xác định
  if [[ -z "$domain" ]]; then
    print_msg error "$ERROR_MISSING_PARAM: --domain"
    print_msg info "$INFO_PARAM_EXAMPLE:\n  --domain=example.tld"
    return 1
  fi

  # Trả về domain sau khi đã parse xong
  echo "$domain"
}

# --log_type
website_log_type_param() {
  local log_type="$1"
  
  # Kiểm tra nếu log_type rỗng hoặc không được truyền
  if [[ -z "$log_type" ]]; then
    print_msg error "$ERROR_MISSING_PARAM: --log_type"
    return 1
  fi

  # Parse tham số --log-type nếu có
  for arg in "$@"; do
    case $arg in
    --log_type=*) log_type="${arg#*=}" ;;
    esac
  done

  # Kiểm tra lại nếu log_type chưa được xác định
  if [[ -z "$log_type" ]]; then
    print_msg error "$ERROR_MISSING_PARAM: --log_type"
    print_msg info "$INFO_PARAM_EXAMPLE:\n  --log_type=error"
    return 1
  fi

  # Trả về log_type sau khi đã parse xong
  echo "$log_type"
}


# --auto_generate
website_auto_generate_param() {
  local auto_generate="$1"
  
  # Kiểm tra nếu auto_generate rỗng hoặc không được truyền
  if [[ -z "$auto_generate" ]]; then
    print_msg error "$ERROR_MISSING_PARAM: --auto_generate"
    return 1
  fi

  # Parse tham số --auto-generate nếu có
  for arg in "$@"; do
    case $arg in
    --auto_generate=*) auto_generate="${arg#*=}" ;;
    esac
  done

  # Kiểm tra lại nếu auto_generate chưa được xác định
  if [[ -z "$auto_generate" ]]; then
    print_msg error "$ERROR_MISSING_PARAM: --auto_generate"
    print_msg info "$INFO_PARAM_EXAMPLE:\n  --auto_generate=true"
    return 1
  fi

  # Trả về auto_generate sau khi đã parse xong
  echo "$auto_generate"
}

# --php
website_php_param() {
  local php="$1"
  
  # Kiểm tra nếu php rỗng hoặc không được truyền
  if [[ -z "$php" ]]; then
    print_msg error "$ERROR_MISSING_PARAM: --php"
    return 1
  fi

  # Parse tham số --php nếu có
  for arg in "$@"; do
    case $arg in
    --php=*) php="${arg#*=}" ;;
    esac
  done

  # Kiểm tra lại nếu php chưa được xác định
  if [[ -z "$php" ]]; then
    print_msg error "$ERROR_MISSING_PARAM: --php"
    print_msg info "$INFO_PARAM_EXAMPLE:\n  --php=8.0"
    return 1
  fi

  # Trả về php sau khi đã parse xong
  echo "$php"
}
# --backup_enabled
website_backup_enabled_param() {
  local backup_enabled="$1"
  
  # Kiểm tra nếu backup_enabled rỗng hoặc không được truyền
  if [[ -z "$backup_enabled" ]]; then
    print_msg error "$ERROR_MISSING_PARAM: --backup_enabled"
    return 1
  fi

  # Parse tham số --backup-enabled nếu có
  for arg in "$@"; do
    case $arg in
    --backup_enabled=*) backup_enabled="${arg#*=}" ;;
    esac
  done

  # Kiểm tra lại nếu backup_enabled chưa được xác định
  if [[ -z "$backup_enabled" ]]; then
    print_msg error "$ERROR_MISSING_PARAM: --backup_enabled"
    print_msg info "$INFO_PARAM_EXAMPLE:\n  --backup_enabled=true"
    return 1
  fi

  # Trả về backup_enabled sau khi đã parse xong
  echo "$backup_enabled"
}