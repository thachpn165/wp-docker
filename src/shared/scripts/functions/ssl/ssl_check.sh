# =====================================
# ssl_logic_check_cert: Check SSL certificate details and expiration for a domain
# Parameters:
#   $1 - domain: The domain to check SSL certificate for
# Requires:
#   - Certificate file must exist at $SSL_DIR/$domain.crt
# Outputs:
#   - Subject, issuer, start and end date, and expiration status
# =====================================
ssl_logic_check_cert() {
  local domain="$1"
  local ssl_dir
  ssl_dir=$SSL_DIR
  local cert_path="$ssl_dir/$domain.crt"

  # Check if certificate file exists
  if [[ ! -f "$cert_path" ]]; then
    print_msg error "$ERROR_SSL_CERT_NOT_FOUND: $cert_path"
    return 1
  fi

  print_msg check "$(printf "$INFO_SSL_CHECKING_FOR_DOMAIN" "$domain")"
  echo ""

  # Extract certificate information
  local subject issuer start_date end_date
  subject=$(openssl x509 -in "$cert_path" -noout -subject | sed 's/subject= //')
  issuer=$(openssl x509 -in "$cert_path" -noout -issuer | sed 's/issuer= //')
  start_date=$(openssl x509 -in "$cert_path" -noout -startdate | cut -d= -f2)
  end_date=$(openssl x509 -in "$cert_path" -noout -enddate | cut -d= -f2)

  # Convert end date to timestamp and get current timestamp
  local end_ts now_ts
  end_ts=$(date -d "$end_date" +%s 2>/dev/null || gdate -d "$end_date" +%s)
  now_ts=$(date +%s)

  local remaining_days=$(((end_ts - now_ts) / 86400))
  local status=""

  # Determine certificate status
  if ((now_ts > end_ts)); then
    status="${RED}❌ EXPIRED${NC}"
  elif ((remaining_days <= 7)); then
    local formatted_expiration_warning
    formatted_expiration_warning="$(printf "$WARNING_SSL_EXPIRING_SOON" "$remaining_days")"
    status=$(print_msg warning "$formatted_expiration_warning")
  else
    local formatted_valid_ssl
    formatted_valid_ssl="$(printf "$SUCCESS_SSL_VALID" "$remaining_days")"
    status=$(print_msg success "$formatted_valid_ssl")
  fi

  # Display certificate details
  echo -e "${CYAN}📄 $LABEL_SSL_DOMAIN:${NC} $subject"
  echo -e "${CYAN}🔒 $LABEL_SSL_ISSUER:${NC} $issuer"
  echo -e "${CYAN}📆 $LABEL_SSL_START_DATE:${NC} $start_date"
  echo -e "${CYAN}📆 $LABEL_SSL_END_DATE:${NC} $end_date"
  echo -e "${CYAN}📊 $LABEL_SSL_STATUS:${NC} $status"
  echo ""
}
