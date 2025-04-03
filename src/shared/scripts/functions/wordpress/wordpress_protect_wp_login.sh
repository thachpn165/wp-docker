#!/bin/bash

wordpress_protect_wp_login_logic() {

    domain="$1"  # site_name will be passed from the menu file or CLI

    SITE_DIR="$SITES_DIR/$domain"
    NGINX_CONF_FILE="$NGINX_PROXY_DIR/conf.d/${domain}.conf"
    AUTH_FILE="$NGINX_PROXY_DIR/globals/.wp-login-auth-$domain"
    INCLUDE_FILE="$NGINX_PROXY_DIR/globals/wp-login-$domain.conf"
    TEMPLATE_FILE="$TEMPLATES_DIR/wp-login-template.conf"

    # 📋 **Choose action to enable/disable wp-login.php protection**
    if [[ "$2" == "enable" ]]; then
        USERNAME=$(openssl rand -hex 4)
        PASSWORD=$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 16)

        # **Create authentication file in the `nginx-proxy/globals` directory**
        echo -e "${YELLOW}🔐 Creating authentication file...${NC}"
        echo "$USERNAME:$(openssl passwd -apr1 $PASSWORD)" > "$AUTH_FILE"

        # **Create wp-login.php configuration file from template**
        echo -e "${YELLOW}📄 Creating wp-login.php configuration file...${NC}"
        if [ -f "$TEMPLATE_FILE" ]; then
            sed "s|\$domain|$domain|g" "$TEMPLATE_FILE" > "$INCLUDE_FILE"
            echo -e "${GREEN}${CHECKMARK} Configuration file created: $INCLUDE_FILE${NC}"
        else
            echo -e "${RED}${CROSSMARK} wp-login-template.conf template not found!${NC}"
            exit 1
        fi

        # **Include configuration file into NGINX right after including cloudflare.conf**
        echo -e "${YELLOW}🔧 Updating NGINX config to include wp-login.php...${NC}"
        if ! grep -q "include /etc/nginx/globals/wp-login-$domain.conf;" "$NGINX_CONF_FILE"; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' "/include \/etc\/nginx\/globals\/cloudflare.conf;/a\\
                include /etc/nginx/globals/wp-login-$domain.conf;" "$NGINX_CONF_FILE"
            else
                sed -i "/include \/etc\/nginx\/globals\/cloudflare.conf;/a\\
                include /etc/nginx/globals/wp-login-$domain.conf;" "$NGINX_CONF_FILE"
            fi
            echo -e "${GREEN}${CHECKMARK} wp-login.php include added to NGINX configuration.${NC}"
            # **Display login information after enabling protection**
            echo -e "${GREEN}${CHECKMARK} wp-login.php is now protected!${NC}"
            echo -e "${YELLOW}${WARNING} You will need this information to access the admin or log in to WordPress. Save it before exiting.${NC}"
            echo -e "🔑 ${CYAN}Login information:${NC}"
            echo -e "  ${GREEN}Username:${NC} $USERNAME"
            echo -e "  ${GREEN}Password:${NC} $PASSWORD"
        fi

    elif [[ "$2" == "disable" ]]; then
        echo -e "${YELLOW}🔧 Removing wp-login.php protection...${NC}"
        if [ -f "$INCLUDE_FILE" ]; then
            echo -e "${YELLOW}🗑️ Deleting wp-login.php configuration file...${NC}"
            rm -f "$INCLUDE_FILE"
            echo -e "${GREEN}${CHECKMARK} wp-login.php configuration file deleted.${NC}"
        fi

        # **Remove include line from NGINX config**
        echo -e "${YELLOW}🔧 Updating NGINX config to remove include...${NC}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' -e "/include \/etc\/nginx\/globals\/wp-login-$domain.conf;/d" "$NGINX_CONF_FILE"
        else
            sed -i -e "/include \/etc\/nginx\/globals\/wp-login-$domain.conf;/d" "$NGINX_CONF_FILE"
        fi
        echo -e "${GREEN}${CHECKMARK} Include line removed.${NC}"

        # **Delete authentication file if it exists**
        if [ -f "$AUTH_FILE" ]; then
            echo -e "${YELLOW}🗑️ Deleting authentication file...${NC}"
            rm -f "$AUTH_FILE"
            echo -e "${GREEN}${CHECKMARK} Authentication file deleted.${NC}"
        fi
    fi

    # **Reload NGINX to apply changes**
    nginx_reload
}
