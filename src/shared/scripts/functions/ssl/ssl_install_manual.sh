ssl_install_manual_cert() {
    select_website
    if [ -z "$SITE_NAME" ]; then
        echo -e "${RED}❌ No website selected.${NC}"
        return 1
    fi

    mkdir -p "$SSL_DIR"
    local target_crt="$SSL_DIR/$SITE_NAME.crt"
    local target_key="$SSL_DIR/$SITE_NAME.key"

    echo -e "${BLUE}🔹 Paste the certificate file content (.crt) for website (including certificate, CA root,...): ${CYAN}$SITE_NAME${NC}"
    echo -e "${YELLOW}👉 End input by pressing Ctrl+D (on Linux/macOS) or Ctrl+Z then Enter (on Windows Git Bash)${NC}"
    echo ""
    cat > "$target_crt"

    echo -e "\n${BLUE}🔹 Paste the private key file content (.key) for website: ${CYAN}$SITE_NAME${NC}"
    echo -e "${YELLOW}👉 End input by pressing Ctrl+D or Ctrl+Z as above${NC}"
    echo ""
    cat > "$target_key"

    # Check if files exist and are not empty
    if [[ ! -s "$target_crt" || ! -s "$target_key" ]]; then
        echo -e "${RED}❌ Installation failed: One of the .crt or .key files is empty or does not exist.${NC}"
        return 1
    fi

    echo -e "${GREEN}✅ Manual certificate has been saved successfully.${NC}"

    echo -e "${YELLOW}🔄 Reloading NGINX Proxy to apply new certificate...${NC}"
    docker exec "$NGINX_PROXY_CONTAINER" nginx -s reload

    echo -e "${GREEN}✅ NGINX Proxy has been reloaded and new certificate has been applied.${NC}"
}
