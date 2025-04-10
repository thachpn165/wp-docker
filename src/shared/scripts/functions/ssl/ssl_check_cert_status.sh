ssl_check_certificate_status_logic() {
  local domain="$1"
  local SSL_DIR="$2"

  if [[ -z "$domain" ]]; then
    print_msg error "$ERROR_NO_WEBSITE_SELECTED"
    return 1
  fi

  local env_file="$SITES_DIR/$domain/.env"
  if [[ ! -f "$env_file" ]]; then
    print_msg error "$ERROR_ENV_NOT_FOUND: $domain"
    return 1
  fi

  local DOMAIN
  DOMAIN=$(fetch_env_variable "$env_file" "DOMAIN")
  if [[ -z "$DOMAIN" ]]; then
    print_msg error "$ERROR_ENV_DOMAIN_NOT_FOUND"
    return 1
  fi

  local cert_path="$SSL_DIR/$DOMAIN.crt"
  if [[ ! -f "$cert_path" ]]; then
    print_msg error "$ERROR_SSL_CERT_NOT_FOUND: $cert_path"
    return 1
  fi

  print_msg check "$(printf "$INFO_SSL_CHECKING_FOR_DOMAIN" "$DOMAIN")"
  echo ""

  local subject issuer start_date end_date
  subject=$(openssl x509 -in "$cert_path" -noout -subject | sed 's/subject= //')
  issuer=$(openssl x509 -in "$cert_path" -noout -issuer | sed 's/issuer= //')
  start_date=$(openssl x509 -in "$cert_path" -noout -startdate | cut -d= -f2)
  end_date=$(openssl x509 -in "$cert_path" -noout -enddate | cut -d= -f2)

  local start_ts end_ts now_ts
  start_ts=$(date -d "$start_date" +%s 2>/dev/null || gdate -d "$start_date" +%s)
  end_ts=$(date -d "$end_date" +%s 2>/dev/null || gdate -d "$end_date" +%s)
  now_ts=$(date +%s)

  local remaining_days=$(( (end_ts - now_ts) / 86400 ))
  local status=""

  if (( now_ts > end_ts )); then
    status="${RED}❌ EXPIRED${NC}"
  elif (( remaining_days <= 7 )); then
    status="${YELLOW}⚠️  Expiring soon ($remaining_days days remaining)${NC}"
  else
    status="${GREEN}✅ Valid ($remaining_days days remaining)${NC}"
  fi

  echo -e "${CYAN}📄 $LABEL_SSL_DOMAIN:${NC} $subject"
  echo -e "${CYAN}🔒 $LABEL_SSL_ISSUER:${NC} $issuer"
  echo -e "${CYAN}📆 $LABEL_SSL_START_DATE:${NC} $start_date"
  echo -e "${CYAN}📆 $LABEL_SSL_END_DATE:${NC} $end_date"
  echo -e "${CYAN}📊 $LABEL_SSL_STATUS:${NC} $status"
  echo ""
}