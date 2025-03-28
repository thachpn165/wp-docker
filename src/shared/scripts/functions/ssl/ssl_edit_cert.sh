ssl_edit_certificate() {
    select_website
    if [ -z "$SITE_NAME" ]; then
        echo -e "${RED}❌ No website selected.${NC}"
        return 1
    fi

    
    local target_crt="$SSL_DIR/$SITE_NAME.crt"
    local target_key="$SSL_DIR/$SITE_NAME.key"

    echo -e "${YELLOW}📝 Editing SSL certificate for website: $SITE_NAME${NC}"

    echo -e "${BLUE}🔹 Paste new content for .crt file:${NC}"
    echo -e "${YELLOW}👉 Press Ctrl+D (Linux/macOS) or Ctrl+Z then Enter (Windows Git Bash) when done${NC}"
    cat > "$target_crt"

    echo -e "\n${BLUE}🔹 Paste new content for .key file:${NC}"
    echo -e "${YELLOW}👉 Press Ctrl+D (Linux/macOS) or Ctrl+Z then Enter (Windows Git Bash) when done${NC}"
    cat > "$target_key"

    # Check files after pasting
    if [[ ! -s "$target_crt" || ! -s "$target_key" ]]; then
        echo -e "${RED}❌ One of the new files is empty. Operation cancelled.${NC}"
        return 1
    fi

    echo -e "${GREEN}✅ Certificate for $SITE_NAME has been updated.${NC}"

    echo -e "${YELLOW}🔄 Reloading NGINX Proxy to apply new certificate...${NC}"
    docker exec "$NGINX_PROXY_CONTAINER" nginx -s reload

    echo -e "${GREEN}✅ NGINX Proxy has been reloaded successfully.${NC}"
}
