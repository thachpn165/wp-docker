ssl_edit_certificate() {
    select_website
    if [ -z "$SITE_NAME" ]; then
        echo -e "${RED}❌ Không có website nào được chọn.${NC}"
        return 1
    fi

    
    local target_crt="$SSL_DIR/$SITE_NAME.crt"
    local target_key="$SSL_DIR/$SITE_NAME.key"

    echo -e "${YELLOW}📝 Đang sửa chứng chỉ SSL cho website: $SITE_NAME${NC}"

    echo -e "${BLUE}🔹 Dán nội dung mới của file .crt:${NC}"
    echo -e "${YELLOW}👉 Nhấn Ctrl+D (Linux/macOS) hoặc Ctrl+Z rồi Enter (Windows Git Bash) khi hoàn tất${NC}"
    cat > "$target_crt"

    echo -e "\n${BLUE}🔹 Dán nội dung mới của file .key:${NC}"
    echo -e "${YELLOW}👉 Nhấn Ctrl+D (Linux/macOS) hoặc Ctrl+Z rồi Enter (Windows Git Bash) khi hoàn tất${NC}"
    cat > "$target_key"

    # Kiểm tra file sau khi paste
    if [[ ! -s "$target_crt" || ! -s "$target_key" ]]; then
        echo -e "${RED}❌ Một trong hai file mới bị rỗng. Hủy thao tác.${NC}"
        return 1
    fi

    echo -e "${GREEN}✅ Chứng chỉ của $SITE_NAME đã được cập nhật.${NC}"

    echo -e "${YELLOW}🔄 Reload NGINX Proxy để áp dụng chứng chỉ mới...${NC}"
    docker exec "$NGINX_PROXY_CONTAINER" nginx -s reload

    echo -e "${GREEN}✅ NGINX Proxy đã được reload thành công.${NC}"
}
