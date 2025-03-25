ssl_check_certificate_status() {
    select_website
    if [ -z "$SITE_NAME" ]; then
        echo -e "${RED}❌ Không có website nào được chọn.${NC}"
        return 1
    fi

    local ENV_FILE="$SITES_DIR/$SITE_NAME/.env"
    if [ ! -f "$ENV_FILE" ]; then
        echo -e "${RED}❌ Không tìm thấy file .env cho site $SITE_NAME${NC}"
        return 1
    fi

    local DOMAIN=$(fetch_env_variable "$ENV_FILE" "DOMAIN")
    if [ -z "$DOMAIN" ]; then
        echo -e "${RED}❌ Không tìm thấy biến DOMAIN trong .env${NC}"
        return 1
    fi

    local CERT_PATH="$SSL_DIR/$DOMAIN.crt"
    if [ ! -f "$CERT_PATH" ]; then
        echo -e "${RED}❌ Không tìm thấy chứng chỉ: $CERT_PATH${NC}"
        return 1
    fi

    echo -e "${BLUE}🔍 Đang kiểm tra chứng chỉ cho domain: ${CYAN}$DOMAIN${NC}"
    echo ""

    # Lấy thông tin chứng chỉ bằng openssl
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
        status="${RED}❌ ĐÃ HẾT HẠN${NC}"
    elif (( remaining_days <= 7 )); then
        status="${YELLOW}⚠️ Sắp hết hạn (còn $remaining_days ngày)${NC}"
    else
        status="${GREEN}✅ Hợp lệ (còn $remaining_days ngày)${NC}"
    fi

    echo -e "${CYAN}📄 Tên miền (Subject):${NC} $subject"
    echo -e "${CYAN}🔒 Cấp bởi (Issuer):  ${NC} $issuer"
    echo -e "${CYAN}📆 Hiệu lực từ:       ${NC} $start_date"
    echo -e "${CYAN}📆 Hết hạn vào:        ${NC} $end_date"
    echo -e "${CYAN}📊 Tình trạng:         ${NC} $status"
    echo ""
}
