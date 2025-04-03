#!/usr/bin/env bash

# ============================================
# ${CHECKMARK} ssl_install_manual_logic.sh – Manual SSL Installation Logic
# ============================================

ssl_install_manual_logic() {
    local domain="$1"
    local SSL_DIR="$2"

    if [ -z "$domain" ]; then
        echo -e "${RED}${CROSSMARK} No website selected.${NC}"
        return 1
    fi

    local target_crt="$SSL_DIR/$domain.crt"
    local target_key="$SSL_DIR/$domain.key"

    # Check if files exist and are not empty
    if [[ ! -s "$target_crt" || ! -s "$target_key" ]]; then
        echo -e "${RED}${CROSSMARK} Installation failed: One of the .crt or .key files is empty or does not exist.${NC}"
        return 1
    fi

    echo -e "${GREEN}${CHECKMARK} Manual certificate has been saved successfully.${NC}"

    echo -e "${YELLOW}🔄 Reloading NGINX Proxy to apply new certificate...${NC}"
    nginx_reload

    echo -e "${GREEN}${CHECKMARK} NGINX Proxy has been reloaded and new certificate has been applied.${NC}"
}