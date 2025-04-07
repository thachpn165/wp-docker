wordpress_protect_wp_login_logic() {
    local domain="$1"
    local action="$2"

    local SITE_DIR="$SITES_DIR/$domain"
    local NGINX_CONF_FILE="$NGINX_PROXY_DIR/conf.d/${domain}.conf"
    local AUTH_FILE="$NGINX_PROXY_DIR/globals/.wp-login-auth-$domain"
    local INCLUDE_FILE="$NGINX_PROXY_DIR/globals/wp-login-$domain.conf"
    local TEMPLATE_FILE="$TEMPLATES_DIR/wp-login-template.conf"

    if [[ -z "$domain" || -z "$action" ]]; then
        print_msg error "$ERROR_MISSING_PARAM"
        exit 1
    fi

    if [[ "$action" == "enable" ]]; then
        local USERNAME
        local PASSWORD
        USERNAME=$(openssl rand -hex 4)
        PASSWORD=$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 16)

        print_msg step "$STEP_WORDPRESS_PROTECT_WP_LOGIN_CREATE_CONF_FILE"
        echo "$USERNAME:$(openssl passwd -apr1 "$PASSWORD")" > "$AUTH_FILE"

        if [[ -f "$TEMPLATE_FILE" ]]; then
            sed "s|\$domain|$domain|g" "$TEMPLATE_FILE" > "$INCLUDE_FILE"
            print_msg success "Đã tạo file cấu hình: $INCLUDE_FILE"
        else
            print_and_debug error "$(printf "$ERROR_FILE_NOT_FOUND" "$TEMPLATE_FILE")"
            exit 1
        fi

        print_msg step "$STEP_WORDPRESS_PROTECT_WP_INCLUDE_NGINX"
        if ! grep -q "include /etc/nginx/globals/wp-login-$domain.conf;" "$NGINX_CONF_FILE"; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' "/include \/etc\/nginx\/globals\/cloudflare.conf;/a\\
                include /etc/nginx/globals/wp-login-$domain.conf;" "$NGINX_CONF_FILE"
            else
                sed -i "/include \/etc\/nginx\/globals\/cloudflare.conf;/a\\
                include /etc/nginx/globals/wp-login-$domain.conf;" "$NGINX_CONF_FILE"
            fi

            print_msg important "$IMPORTANT_WORDPRESS_PROTECT_WP_LOGIN_INSTALLED:"
            echo -e "  ${GREEN}Username:${NC} $USERNAME"
            echo -e "  ${GREEN}Password:${NC} $PASSWORD"
        fi

    elif [[ "$action" == "disable" ]]; then
        print_msg step "$STEP_WORDPRESS_PROTECT_WP_LOGIN_DISABLE"

        if [[ -f "$INCLUDE_FILE" ]]; then
            rm -f "$INCLUDE_FILE"
        fi

        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' -e "/include \/etc\/nginx\/globals\/wp-login-$domain.conf;/d" "$NGINX_CONF_FILE"
        else
            sed -i -e "/include \/etc\/nginx\/globals\/wp-login-$domain.conf;/d" "$NGINX_CONF_FILE"
        fi

        if [[ -f "$AUTH_FILE" ]]; then
            rm -f "$AUTH_FILE"
        fi

    else
        print_msg error "$ERROR_INVALID_CHOICE"
        exit 1
    fi

    # 🔄 Reload NGINX
    nginx_reload
}