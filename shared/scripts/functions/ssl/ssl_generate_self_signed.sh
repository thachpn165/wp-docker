ssl_generate_self_signed() {
    select_website
    if [ -z "$SITE_NAME" ]; then
        echo -e "${RED}❌ Không có website nào được chọn.${NC}"
        return 1
    fi

    
    local CERT_PATH="$SSL_DIR/$SITE_NAME.crt"
    local KEY_PATH="$SSL_DIR/$SITE_NAME.key"

    if [ ! -d "$SSL_DIR" ]; then
        echo -e "${RED}❌ Thư mục SSL không tồn tại: $SSL_DIR${NC}"
        return 1
    fi

    echo -e "${YELLOW}🔐 Đang tạo lại chứng chỉ tự ký cho site: $SITE_NAME...${NC}"
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout "$KEY_PATH" \
        -out "$CERT_PATH" \
        -subj "/C=VN/ST=HCM/L=HCM/O=WP-Docker/OU=Dev/CN=$SITE_NAME"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Đã tạo lại chứng chỉ SSL tự ký thành công cho $SITE_NAME.${NC}"
        echo -e "${YELLOW}🔄 Đang reload lại container nginx-proxy...${NC}"
        docker exec "$NGINX_PROXY_CONTAINER" nginx -s reload
        echo -e "${GREEN}✅ NGINX Proxy đã được reload thành công.${NC}"
    else
        echo -e "${RED}❌ Tạo chứng chỉ SSL thất bại.${NC}"
        return 1
    fi
}
