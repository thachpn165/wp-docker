ssl_check_certificate_status() {
    select_website
    if [ -z "$SITE_NAME" ]; then
        echo -e "${RED}❌ No website selected.${NC}"
        return 1
    fi

    local ENV_FILE="$SITES_DIR/$SITE_NAME/.env"
    if [ ! -f "$ENV_FILE" ]; then
        echo -e "${RED}❌ .env file not found for site $SITE_NAME${NC}"
        return 1
    fi

    local DOMAIN=$(fetch_env_variable "$ENV_FILE" "DOMAIN")
    if [ -z "$DOMAIN" ]; then
        echo -e "${RED}❌ DOMAIN variable not found in .env${NC}"
        return 1
    fi

    local CERT_PATH="$SSL_DIR/$DOMAIN.crt"
    if [ ! -f "$CERT_PATH" ]; then
        echo -e "${RED}❌ Certificate not found: $CERT_PATH${NC}"
        return 1
    fi

    echo -e "${BLUE}🔍 Checking certificate for domain: ${CYAN}$DOMAIN${NC}"
    echo ""

    # Get certificate information using openssl
    local subject issuer start_date end_date
    subject=$(openssl x509 -in "$CERT_PATH" -noout -subject | sed 's/subject= //')
    issuer=$(openssl x509 -in "$CERT_PATH" -noout -issuer | sed 's/issuer= //')
    start_date=$(openssl x509 -in "$CERT_PATH" -noout -startdate | cut -d= -f2)
    end_date=$(openssl x509 -in "$CERT_PATH" -noout -enddate | cut -d= -f2)

    local start_ts end_ts now_ts
    start_ts=$(date -d "$start_date" +%s 2>/dev/null || gdate -d "$start_date" +%s)
    end_ts=$(date -d "$end_date" +%s 2>/dev/null || gdate -d "$end_date" +%s)
    now_ts=$(date +%s)

    local status=""
    local remaining_days=$(( (end_ts - now_ts) / 86400 ))

    if (( now_ts > end_ts )); then
        status="${RED}❌ EXPIRED${NC}"
    elif (( remaining_days <= 7 )); then
        status="${YELLOW}⚠️ Expiring soon ($remaining_days days remaining)${NC}"
    else
        status="${GREEN}✅ Valid ($remaining_days days remaining)${NC}"
    fi

    echo -e "${CYAN}📄 Domain (Subject):${NC} $subject"
    echo -e "${CYAN}🔒 Issued by:       ${NC} $issuer"
    echo -e "${CYAN}📆 Valid from:      ${NC} $start_date"
    echo -e "${CYAN}📆 Expires on:       ${NC} $end_date"
    echo -e "${CYAN}📊 Status:           ${NC} $status"
    echo ""
}
