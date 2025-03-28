ssl_generate_self_signed() {
    select_website
    if [ -z "$SITE_NAME" ]; then
        echo -e "${RED}❌ No website selected.${NC}"
        return 1
    fi

    
    local CERT_PATH="$SSL_DIR/$SITE_NAME.crt"
    local KEY_PATH="$SSL_DIR/$SITE_NAME.key"

    if [ ! -d "$SSL_DIR" ]; then
        echo -e "${RED}❌ SSL directory not found: $SSL_DIR${NC}"
        return 1
    fi

    echo -e "${YELLOW}🔐 Regenerating self-signed certificate for site: $SITE_NAME...${NC}"
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout "$KEY_PATH" \
        -out "$CERT_PATH" \
        -subj "/C=VN/ST=HCM/L=HCM/O=WP-Docker/OU=Dev/CN=$SITE_NAME"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Self-signed SSL certificate has been regenerated successfully for $SITE_NAME.${NC}"
        echo -e "${YELLOW}🔄 Reloading nginx-proxy container...${NC}"
        docker exec "$NGINX_PROXY_CONTAINER" nginx -s reload
        echo -e "${GREEN}✅ NGINX Proxy has been reloaded successfully.${NC}"
    else
        echo -e "${RED}❌ Failed to generate SSL certificate.${NC}"
        return 1
    fi
}
