ssl_install_manual_cert() {
    select_website
    if [ -z "$SITE_NAME" ]; then
        echo -e "${RED}❌ Không có website nào được chọn.${NC}"
        return 1
    fi

    mkdir -p "$SSL_DIR"
    local target_crt="$SSL_DIR/$SITE_NAME.crt"
    local target_key="$SSL_DIR/$SITE_NAME.key"

    echo -e "${BLUE}🔹 Dán nội dung file chứng chỉ (.crt) cho website (bao gồm chứng chỉ, CA root,...): ${CYAN}$SITE_NAME${NC}"
    echo -e "${YELLOW}👉 Kết thúc việc nhập bằng cách nhấn Ctrl+D (trên Linux/macOS) hoặc Ctrl+Z rồi Enter (trên Windows Git Bash)${NC}"
    echo ""
    cat > "$target_crt"

    echo -e "\n${BLUE}🔹 Dán nội dung file private key (.key) cho website: ${CYAN}$SITE_NAME${NC}"
    echo -e "${YELLOW}👉 Kết thúc việc nhập bằng cách nhấn Ctrl+D hoặc Ctrl+Z như trên${NC}"
    echo ""
    cat > "$target_key"

    # Kiểm tra file tồn tại và không rỗng
    if [[ ! -s "$target_crt" || ! -s "$target_key" ]]; then
        echo -e "${RED}❌ Cài đặt thất bại: Một trong hai file .crt hoặc .key rỗng hoặc không tồn tại.${NC}"
        return 1
    fi

    echo -e "${GREEN}✅ Chứng chỉ thủ công đã được lưu thành công.${NC}"

    echo -e "${YELLOW}🔄 Reload NGINX Proxy để áp dụng chứng chỉ mới...${NC}"
    docker exec "$NGINX_PROXY_CONTAINER" nginx -s reload

    echo -e "${GREEN}✅ NGINX Proxy đã được reload và chứng chỉ mới đã áp dụng.${NC}"
}
