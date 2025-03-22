ssl_install_lets_encrypt() {
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

    echo -e "${BLUE}🌍 Domain: ${CYAN}$DOMAIN${NC}"
    echo -e "${YELLOW}🔍 Đang kiểm tra certbot...${NC}"

    if ! command -v certbot &> /dev/null; then
        echo -e "${YELLOW}⚠️ certbot chưa được cài. Đang tiến hành cài đặt...${NC}"

        if [[ "$(uname -s)" == "Linux" ]]; then
            if [ -f /etc/debian_version ]; then
                sudo apt update
                sudo apt install -y certbot
            elif [ -f /etc/redhat-release ] || [ -f /etc/centos-release ]; then
                sudo yum install -y certbot
            else
                echo -e "${RED}❌ Không hỗ trợ hệ điều hành này để cài certbot.${NC}"
                return 1
            fi
        else
            echo -e "${RED}❌ certbot chỉ được hỗ trợ tự động cài trên Linux. Hãy cài thủ công trên macOS.${NC}"
            return 1
        fi
    fi

    echo -e "${YELLOW}📦 Đang yêu cầu chứng chỉ Let's Encrypt cho $DOMAIN...${NC}"
    sudo certbot certonly --standalone -d "$DOMAIN" --non-interactive --agree-tos -m "admin@$DOMAIN"

    local CERT_PATH="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
    local KEY_PATH="/etc/letsencrypt/live/$DOMAIN/privkey.pem"

    if [[ ! -f "$CERT_PATH" || ! -f "$KEY_PATH" ]]; then
        echo -e "${RED}❌ Không tìm thấy chứng chỉ sau khi cấp. Có thể domain chưa trỏ đúng hoặc port 80 bị chặn.${NC}"
        return 1
    fi

    echo -e "${GREEN}✅ Chứng chỉ đã được cấp thành công từ Let's Encrypt.${NC}"

    local SSL_DIR="nginx-proxy/ssl"
    mkdir -p "$SSL_DIR"

    local TARGET_CERT="$SSL_DIR/$SITE_NAME.crt"
    local TARGET_KEY="$SSL_DIR/$SITE_NAME.key"

    sudo cp "$CERT_PATH" "$TARGET_CERT"
    sudo cp "$KEY_PATH" "$TARGET_KEY"

    echo -e "${YELLOW}🔄 Reload NGINX Proxy để áp dụng chứng chỉ mới...${NC}"
    docker exec "$NGINX_PROXY_CONTAINER" nginx -s reload

    echo -e "${GREEN}✅ Cài đặt chứng chỉ Let's Encrypt hoàn tất và đã áp dụng cho $SITE_NAME.${NC}"
}
