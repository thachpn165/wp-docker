ssl_edit_certificate_logic() {
    if [ -z "$SITE_NAME" ]; then
        echo -e "${RED}${CROSSMARK} No website selected.${NC}"
        return 1
    fi

    local target_crt="$SSL_DIR/$SITE_NAME.crt"
    local target_key="$SSL_DIR/$SITE_NAME.key"

    # Check if the SSL files exist
    if [[ ! -f "$target_crt" || ! -f "$target_key" ]]; then
        echo -e "${RED}${CROSSMARK} SSL certificate files not found for $SITE_NAME.${NC}"
        return 1
    fi

    # Proceed to edit the certificate (no interaction here)
    echo -e "${YELLOW}📝 Editing SSL certificate for website: $SITE_NAME${NC}"

    # Request user to input the new certificate and key
    echo -e "${YELLOW}Please paste the new SSL certificate for $SITE_NAME:${NC}"
    read -r new_cert
    echo -e "${YELLOW}Please paste the new private key for $SITE_NAME:${NC}"
    read -r new_key

    # Save the new certificate and key to the appropriate files
    echo "$new_cert" > "$target_crt"
    echo "$new_key" > "$target_key"

    echo -e "${GREEN}${CHECKMARK} Certificate for $SITE_NAME has been updated successfully.${NC}"

    # Reload NGINX Proxy to apply new certificate
    echo -e "${YELLOW}🔄 Reloading NGINX Proxy to apply new certificate...${NC}"
    nginx_reload

    echo -e "${GREEN}${CHECKMARK} NGINX Proxy has been reloaded successfully.${NC}"
}