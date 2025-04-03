ssl_generate_self_signed_logic() {
    local SITE_DOMAIN=$1
    # Set SSL directory to a temporary directory if in test mode
    local SSL_DIR="${TEST_MODE:+/tmp/test_ssl_directory}"

    # Default SSL directory if not in TEST_MODE
    if [[ "$TEST_MODE" != true ]]; then
        SSL_DIR="$NGINX_PROXY_DIR/ssl"
    fi

    local CERT_PATH="$SSL_DIR/$domain.crt"
    local KEY_PATH="$SSL_DIR/$domain.key"

    if [ -z "$domain" ]; then
        echo -e "${RED}${CROSSMARK} No website selected.${NC}"
        return 1
    fi

    # Skip checking website directory in TEST_MODE
    if [[ "$TEST_MODE" != true ]]; then
        if [ ! -d "$PROJECT_DIR/sites/$domain" ]; then
            echo -e "${RED}${CROSSMARK} Website '$domain' does not exist.${NC}"
            return 1
        fi
    fi

    if [ ! -d "$SSL_DIR" ]; then
        echo -e "${RED}${CROSSMARK} SSL directory not found: $SSL_DIR${NC}"
        return 1
    fi

    echo -e "${YELLOW}🔐 Regenerating self-signed certificate for site: $domain...${NC}"
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout "$KEY_PATH" \
        -out "$CERT_PATH" \
        -subj "/C=VN/ST=HCM/L=HCM/O=WP-Docker/OU=Dev/CN=$domain"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}${CHECKMARK} Self-signed SSL certificate has been regenerated successfully for $domain.${NC}"
        echo -e "${YELLOW}🔄 Reloading nginx-proxy container...${NC}"
        nginx_reload
        echo ""
        echo -e "${GREEN}${CHECKMARK} NGINX Proxy has been reloaded successfully.${NC}"
        echo -e "Your SSL certification: $CERT_PATH"
        echo -e "Your SSL key: $KEY_PATH"
    else
        echo -e "${RED}${CROSSMARK} Failed to generate SSL certificate.${NC}"
        return 1
    fi
}