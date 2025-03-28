ssl_install_lets_encrypt() {
    select_website
    if [ -z "$SITE_NAME" ]; then
        echo -e "${RED}❌ No website selected.${NC}"
        return 1
    fi

    local ENV_FILE="$SITES_DIR/$SITE_NAME/.env"
    if [ ! -f "$ENV_FILE" ]; then
        echo -e "${RED}❌ .env file not found for site $SITE_NAME${NC}"
        return 1
    fi

    local DOMAIN=$(fetch_env_variable "$ENV_FILE" "DOMAIN")
    if [ -z "$DOMAIN" ]; then
        echo -e "${RED}❌ DOMAIN variable not found in .env${NC}"
        return 1
    fi

    echo -e "${BLUE}🌍 Domain: ${CYAN}$DOMAIN${NC}"

    # Determine webroot path (where WordPress source code is located)
    local WEBROOT="$SITES_DIR/$SITE_NAME/wordpress"

    if [ ! -d "$WEBROOT" ]; then
        echo -e "${RED}❌ Source code directory not found: $WEBROOT${NC}"
        return 1
    fi

    # Check certbot
    if ! command -v certbot &> /dev/null; then
        echo -e "${YELLOW}⚠️ certbot is not installed. Proceeding with installation...${NC}"
        if [[ "$(uname -s)" == "Linux" ]]; then
            if [ -f /etc/debian_version ]; then
                sudo apt update && sudo apt install -y certbot
            elif [ -f /etc/redhat-release ] || [ -f /etc/centos-release ]; then
                sudo yum install epel-release -y && sudo yum install -y certbot
            else
                echo -e "${RED}❌ This operating system is not supported for automatic certbot installation.${NC}"
                return 1
            fi
        else
            echo -e "${RED}❌ certbot automatic installation is only supported on Linux. Please install manually on macOS.${NC}"
            return 1
        fi
    fi

    echo -e "${YELLOW}📦 Requesting certificate from Let's Encrypt using webroot method...${NC}"
    sudo certbot certonly --webroot -w "$WEBROOT" -d "$DOMAIN" --non-interactive --agree-tos -m "admin@$DOMAIN"

    local CERT_PATH="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
    local KEY_PATH="/etc/letsencrypt/live/$DOMAIN/privkey.pem"

    if [[ ! -f "$CERT_PATH" || ! -f "$KEY_PATH" ]]; then
        echo -e "${RED}❌ Certificate not found after issuance. Please check domain and configuration.${NC}"
        return 1
    fi

    echo -e "${GREEN}✅ Certificate has been successfully issued by Let's Encrypt.${NC}"

    
    mkdir -p "$SSL_DIR"

    sudo cp "$CERT_PATH" "$SSL_DIR/$DOMAIN.crt"
    sudo cp "$KEY_PATH" "$SSL_DIR/$DOMAIN.key"

    echo -e "${YELLOW}🔄 Reloading NGINX Proxy to apply new certificate...${NC}"
    docker exec "$NGINX_PROXY_CONTAINER" nginx -s reload

    echo -e "${GREEN}✅ Let's Encrypt has been successfully installed for site ${CYAN}$DOMAIN${NC}"
}
