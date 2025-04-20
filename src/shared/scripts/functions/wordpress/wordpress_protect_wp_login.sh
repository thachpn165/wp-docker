wordpress_prompt_protect_wplogin() {
    local domain 
    # 📋 Select website
    website_get_selected domain
    if [[ -z "$domain" ]]; then
        print_msg error "$ERROR_NO_WEBSITE_SELECTED"
        exit 1
    fi
    _is_valid_domain "$domain" || return 1

    # 📋 Choose action
    echo ""
    print_msg question "$(printf "$QUESTION_PROTECT_WPLOGIN_ACTION" "$domain")"
    echo "1) $LABEL_PROTECT_WPLOGIN_ENABLE"
    echo "2) $LABEL_PROTECT_WPLOGIN_DISABLE"

    action_choice=$(get_input_or_test_value "$PROMPT_ENTER_ACTION_NUMBER" "${TEST_ACTION:-1}")

    if [[ "$action_choice" == "1" ]]; then
        action="enable"
    elif [[ "$action_choice" == "2" ]]; then
        action="disable"
    else
        print_msg error "$ERROR_INVALID_CHOICE"
        exit 1
    fi

    # ▶️ Run CLI
    wordpress_cli_protect_wplogin --domain="$domain" --action="$action"

}
# =====================================
# wordpress_protect_wp_login_logic: Enable or disable basic auth protection for wp-login.php
# Parameters:
#   $1 - domain
#   $2 - action ("enable" or "disable")
# Behavior:
#   - Generates .htpasswd and include config file if enabled
#   - Removes config and auth file if disabled
#   - Modifies NGINX config and reloads nginx
# =====================================
wordpress_protect_wp_login_logic() {
    local domain="$1"
    local action="$2"
    local NGINX_CONF_FILE="$NGINX_PROXY_DIR/conf.d/${domain}.conf"
    local AUTH_FILE="$NGINX_PROXY_DIR/globals/.wp-login-auth-$domain"
    local INCLUDE_FILE="$NGINX_PROXY_DIR/globals/wp-login-$domain.conf"
    local TEMPLATE_FILE="$TEMPLATES_DIR/wp-login-template.conf"

    if [[ -z "$domain" || -z "$action" ]]; then
        print_msg error "$ERROR_MISSING_PARAM: --domain, --action"
        exit 1
    fi
    _id_valid_domain "$domain" || return 1
    if ! json_key_exists ".site[\"$domain\"]"; then
        print_msg error "$ERROR_SITE_NOT_EXIST: $domain"
        return 1
    fi

    if [[ "$action" == "enable" ]]; then
        local USERNAME
        local PASSWORD
        USERNAME=$(openssl rand -hex 4)
        PASSWORD=$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 16)

        print_msg step "$STEP_WORDPRESS_PROTECT_WP_LOGIN_CREATE_CONF_FILE"
        echo "$USERNAME:$(openssl passwd -apr1 "$PASSWORD")" >"$AUTH_FILE"

        if [[ -f "$TEMPLATE_FILE" ]]; then
            sed "s|\$domain|$domain|g" "$TEMPLATE_FILE" >"$INCLUDE_FILE"
            print_msg success "Successfully created config file: $INCLUDE_FILE"
        else
            print_and_debug error "$(printf "$ERROR_FILE_NOT_FOUND" "$TEMPLATE_FILE")"
            exit 1
        fi

        print_msg step "$STEP_WORDPRESS_PROTECT_WP_INCLUDE_NGINX"
        if ! grep -q "include /etc/nginx/globals/wp-login-$domain.conf;" "$NGINX_CONF_FILE"; then
            sedi "/include \/etc\/nginx\/globals\/cloudflare.conf;/a\\
            include /etc/nginx/globals/wp-login-$domain.conf;" "$NGINX_CONF_FILE"

            print_msg important "$IMPORTANT_WORDPRESS_PROTECT_WP_LOGIN_INSTALLED:"
            echo -e "  ${GREEN}Username:${NC} $USERNAME"
            echo -e "  ${GREEN}Password:${NC} $PASSWORD"
        fi

    elif [[ "$action" == "disable" ]]; then
        print_msg step "$STEP_WORDPRESS_PROTECT_WP_LOGIN_DISABLE"

        if [[ -f "$INCLUDE_FILE" ]]; then
            rm -f "$INCLUDE_FILE"
        fi

        sedi "/include \/etc\/nginx\/globals\/wp-login-$domain.conf;/d" "$NGINX_CONF_FILE"

        if [[ -f "$AUTH_FILE" ]]; then
            rm -f "$AUTH_FILE"
        fi

        print_msg success "$SUCCESS_WORDPRESS_PROTECT_WP_LOGIN_DISABLED"

    else
        print_msg error "$ERROR_INVALID_CHOICE"
        exit 1
    fi

    # 🔄 Reload NGINX
    print_msg step "Reloading NGINX"
    nginx_reload
}
