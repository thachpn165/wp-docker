#!/usr/bin/env bash

# ============================================
# ✅ ssl_install_manual_logic.sh – Manual SSL Installation Logic
# ============================================

ssl_install_manual_logic() {
    local SITE_NAME="$1"
    local SSL_DIR="$2"

    if [ -z "$SITE_NAME" ]; then
        echo -e "${RED}❌ No website selected.${NC}"
        return 1
    fi

    local target_crt="$SSL_DIR/$SITE_NAME.crt"
    local target_key="$SSL_DIR/$SITE_NAME.key"

    # Check if files exist and are not empty
    if [[ ! -s "$target_crt" || ! -s "$target_key" ]]; then
        echo -e "${RED}❌ Installation failed: One of the .crt or .key files is empty or does not exist.${NC}"
        return 1
    fi

    echo -e "${GREEN}✅ Manual certificate has been saved successfully.${NC}"

    echo -e "${YELLOW}🔄 Reloading NGINX Proxy to apply new certificate...${NC}"
    nginx_reload

    echo -e "${GREEN}✅ NGINX Proxy has been reloaded and new certificate has been applied.${NC}"
}