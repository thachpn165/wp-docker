ssl_install_lets_encrypt_logic() {
    local ENV_FILE="$SITES_DIR/$domain/.env"
    if [ ! -f "$ENV_FILE" ]; then
        echo -e "${RED}${CROSSMARK} .env file not found for site $domain${NC}"
        return 1
    fi

    local DOMAIN=$(fetch_env_variable "$ENV_FILE" "DOMAIN")
    if [ -z "$DOMAIN" ]; then
        echo -e "${RED}${CROSSMARK} DOMAIN variable not found in .env${NC}"
        return 1
    fi

    echo -e "${BLUE}🌍 Domain: ${CYAN}$DOMAIN${NC}"

    # Determine webroot path (where WordPress source code is located)
    local WEBROOT="$SITES_DIR/$domain/wordpress"

    if [ ! -d "$WEBROOT" ]; then
        echo -e "${RED}${CROSSMARK} Source code directory not found: $WEBROOT${NC}"
        return 1
    fi

    # Check certbot installation
    if ! command -v certbot &> /dev/null; then
        echo -e "${YELLOW}${WARNING} certbot is not installed. Proceeding with installation...${NC}"
        if [[ "$(uname -s)" == "Linux" ]]; then
            if [ -f /etc/debian_version ]; then
                 apt update && apt install -y certbot
            elif [ -f /etc/redhat-release ] || [ -f /etc/centos-release ]; then
                 yum install epel-release -y && yum install -y certbot
            else
                echo -e "${RED}${CROSSMARK} This operating system is not supported for automatic certbot installation.${NC}"
                return 1
            fi
        else
            echo -e "${RED}${CROSSMARK} certbot automatic installation is only supported on Linux. Please install manually on macOS.${NC}"
            return 1
        fi
    fi

    echo -e "${YELLOW}📦 Requesting certificate from Let's Encrypt using webroot method...${NC}"
    certbot certonly --webroot -w "$WEBROOT" -d "$DOMAIN" --non-interactive --agree-tos -m "admin@$DOMAIN"

    local CERT_PATH="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
    local KEY_PATH="/etc/letsencrypt/live/$DOMAIN/privkey.pem"

    if [[ ! -f "$CERT_PATH" || ! -f "$KEY_PATH" ]]; then
        echo -e "${RED}${CROSSMARK} Certificate not found after issuance. Please check domain and configuration.${NC}"
        return 1
    fi

    echo -e "${GREEN}${CHECKMARK} Certificate has been successfully issued by Let's Encrypt.${NC}"

    mkdir -p "$SSL_DIR"
    cp "$CERT_PATH" "$SSL_DIR/$DOMAIN.crt"
    cp "$KEY_PATH" "$SSL_DIR/$DOMAIN.key"

    echo -e "${YELLOW}🔄 Reloading NGINX Proxy to apply new certificate...${NC}"
    docker exec "$NGINX_PROXY_CONTAINER" nginx -s reload

    echo -e "${GREEN}${CHECKMARK} Let's Encrypt has been successfully installed for site ${CYAN}$DOMAIN${NC}"
}