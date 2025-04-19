# ===========================================
# PROMPTS FOR SSL INSTALLATION
# ===========================================

# =====================================
# ssl_prompt_general: Wrapper function to select website and call SSL setup logic
# Parameters:
#   $1 - callback_function: Name of the logic function to call
# =====================================
ssl_prompt_general() {
    local callback_function="$1"
    local domain

    # Select website
    website_get_selected domain
    if [[ -z "$domain" ]]; then
        print_and_debug error "$ERROR_NO_WEBSITE_SELECTED"
        return 1
    fi
    # Validate callback function existence
    if [[ "$(type -t "$callback_function")" != "function" ]]; then
        print_and_debug error "Error: Function $callback_function does not exist"
        return 1
    fi

    # Call the logic function with selected domain
    "$callback_function" "$domain"
    return $?
}

ssl_prompt_letsencrypt() {
    local domain email staging

    # Prompt for $domain
    website_get_selected domain
    if [[ -z "$domain" ]]; then
        print_and_debug error "$ERROR_NO_WEBSITE_SELECTED"
        return 1
    fi
    # Prompt for email
    email=$(get_input_or_test_value "$PROMPT_ENTER_EMAIL" "test@local")
    if [[ -z "$email" ]]; then
        print_and_debug error "$ERROR_MISSING_EMAIL"
        email=$(get_input_or_test_value "$PROMPT_ENTER_EMAIL" "test@local")
    fi
    # Send command to install SSL
    ssl_cli_install_letsencrypt --domain="$domain" --email="$email"
}
# ===========================================
# SSL INSTALLATION LOGIC
# ===========================================

# =====================================
# ssl_logic_install_selfsigned: Generate a self-signed SSL certificate for a domain
# Parameters:
#   $1 - domain: Target domain
# =====================================
ssl_logic_install_selfsigned() {
    local domain="$1"

    if [[ -z "$domain" ]]; then
        print_and_debug error "$ERROR_SITE_NOT_SELECTED"
        return 1
    fi

    local ssl_dir
    ssl_dir="${TEST_MODE:+/tmp/test_ssl_directory}"
    [[ "$TEST_MODE" != true ]] && ssl_dir="$NGINX_PROXY_DIR/ssl"

    local cert_path="$ssl_dir/$domain.crt"
    local key_path="$ssl_dir/$domain.key"

    debug_log "[SSL] Certificate path: $cert_path"
    debug_log "[SSL] Key path: $key_path"

    # Ensure site exists (if not in test mode)
    if [[ "$TEST_MODE" != true ]]; then
        if [[ ! -d "$PROJECT_DIR/sites/$domain" ]]; then
            print_and_debug error "$(printf "$ERROR_SITE_NOT_EXIST" "$domain")"
            return 1
        fi
    fi

    # Ensure SSL directory exists
    is_directory_exist "$ssl_dir" || {
        print_and_debug error "$MSG_NOT_FOUND: $ssl_dir"
        mkdir -p "$ssl_dir"
        debug_log "[SSL] Not found and created: $ssl_dir"
        return 1
    }

    print_msg step "$(printf "$STEP_SSL_REGENERATE_SELF_SIGNED" "$domain")"

    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout "$key_path" \
        -out "$cert_path" \
        -subj "/C=VN/ST=HCM/L=HCM/O=WP-Docker/OU=Dev/CN=$domain"

    if [[ $? -eq 0 ]]; then
        print_msg success "$(printf "$SUCCESS_SSL_SELF_SIGNED_GENERATED" "$domain")"
        print_msg step "$STEP_NGINX_RELOADING"
        nginx_reload
        print_msg success "$SUCCESS_NGINX_RELOADED"
        print_msg info "$(printf "$INFO_SSL_CERT_PATH" "$cert_path")"
        print_msg info "$(printf "$INFO_SSL_KEY_PATH" "$key_path")"
    else
        print_and_debug error "$ERROR_SSL_SELF_SIGNED_GENERATE_FAILED"
        return 1
    fi
}

# =====================================
# ssl_logic_install_letsencrypt: Issue SSL cert using Let's Encrypt (certbot)
# Parameters:
#   $1 - domain
#   $2 - email for registration
#   $3 - staging mode (true/false)
# =====================================
ssl_logic_install_letsencrypt() {
    local domain="$1"
    local email="$2"
    local staging="$3"

    if [[ -z "$domain" ]]; then
        print_and_debug error "$ERROR_MISSING_PARAM: --domain"
        return 1
    fi

    print_msg info "$(printf "$INFO_DOMAIN_SELECTED" "$domain")"

    local ssl_dir=${SSL_DIR:-"$NGINX_PROXY_DIR/ssl"}
    local webroot="$SITES_DIR/$domain/wordpress"
    local certbot_data="$BASE_DIR/.certbot"

    if [[ ! -d "$webroot" ]]; then
        print_and_debug error "$ERROR_DIRECTORY_NOT_FOUND: $webroot"
        return 1
    fi

    is_directory_exist "$ssl_dir" || mkdir -p "$ssl_dir"
    mkdir -p "$certbot_data"

    print_msg step "$STEP_REQUEST_CERT_WEBROOT"
    debug_log "[SSL] Running certbot container for domain: $domain with webroot: $webroot"

    local certbot_args=(
        certonly --webroot -w /var/www/html -d "$domain" \
        --non-interactive --agree-tos -m "$email"
    )
    [[ "$staging" == "true" ]] && certbot_args+=(--staging)

    docker run --rm \
        -v "$webroot:/var/www/html" \
        -v "$certbot_data:/etc/letsencrypt" \
        certbot/certbot "${certbot_args[@]}"

    local CERT_PATH="$certbot_data/live/$domain/fullchain.pem"
    local KEY_PATH="$certbot_data/live/$domain/privkey.pem"

    if [[ ! -f "$CERT_PATH" || ! -f "$KEY_PATH" ]]; then
        print_and_debug error "$(printf "$ERROR_SSL_CERT_NOT_FOUND" "$domain")"
        return 1
    fi

    print_msg success "$SUCCESS_SSL_LETS_ENCRYPT_ISSUED: $domain"
    debug_log "[SSL] Copying certificate to directory: $ssl_dir"

    run_cmd "sudo chown -R $USER:$USER $ssl_dir"
    copy_file "$CERT_PATH" "$ssl_dir/$domain.crt"
    copy_file "$KEY_PATH" "$ssl_dir/$domain.key"

    debug_log "[SSL] Certificate copied successfully: $ssl_dir/$domain.crt and $ssl_dir/$domain.key"

    print_msg step "$STEP_NGINX_RELOADING"
    nginx_restart
    print_msg success "$(printf "$SUCCESS_SSL_INSTALLED" "$domain")"
}


# =====================================
# ssl_logic_install_manual: Use manually provided SSL certificate and key
# Parameters:
#   $1 - domain
#   $2 - SSL_DIR (destination)
# =====================================
ssl_logic_install_manual() {
    local domain="$1"
    local SSL_DIR="$2"

    if [[ -z "$domain" ]]; then
        print_and_debug error "$ERROR_SITE_NOT_SELECTED"
        return 1
    fi

    is_directory_exist "$ssl_dir" || {
        print_and_debug error "$MSG_NOT_FOUND: $ssl_dir"
        mkdir -p "$ssl_dir"
        debug_log "[SSL] Not found and created: $ssl_dir"
        return 1
    }

    local target_crt="$SSL_DIR/$domain.crt"
    local target_key="$SSL_DIR/$domain.key"

    debug_log "[SSL INSTALL MANUAL] Domain: $domain"
    debug_log "[SSL INSTALL MANUAL] CRT path: $target_crt"
    debug_log "[SSL INSTALL MANUAL] KEY path: $target_key"

    if [[ ! -s "$target_crt" || ! -s "$target_key" ]]; then
        print_and_debug error "$ERROR_SSL_FILE_EMPTY_OR_MISSING"
        return 1
    fi

    print_msg success "$SUCCESS_SSL_MANUAL_SAVED"

    print_msg step "$STEP_NGINX_RELOADING"
    nginx_reload
    print_msg success "$SUCCESS_NGINX_RELOADED"
}

# =====================================
# ssl_logic_edit_cert: Replace current SSL certificate with new pasted content
# Parameters:
#   $1 - domain
# =====================================
ssl_logic_edit_cert() {
    local domain="$1"

    if [[ -z "$domain" ]]; then
        print_and_debug error "$ERROR_NO_WEBSITE_SELECTED"
        return 1
    fi

    local target_crt="$SSL_DIR/$domain.crt"
    local target_key="$SSL_DIR/$domain.key"

    if [[ ! -f "$target_crt" || ! -f "$target_key" ]]; then
        print_and_debug error "$(printf "$ERROR_SSL_CERT_NOT_FOUND_FOR_DOMAIN" "$domain")"
        return 1
    fi

    print_msg info "$(printf "$INFO_SSL_EDITING_FOR_DOMAIN" "$domain")"

    print_msg question "$(printf "$PROMPT_SSL_ENTER_NEW_CRT" "$domain")"
    read -r new_cert
    new_cert=$(get_input_or_test_value "$new_cert" "$PROMPT_SSL_ENTER_NEW_CRT" "$domain")

    print_msg question "$(printf "$PROMPT_SSL_ENTER_NEW_KEY" "$domain")"
    new_key=$(get_input_or_test_value "$new_key" "$PROMPT_SSL_ENTER_NEW_KEY" "$domain")

    echo "$new_cert" >"$target_crt"
    echo "$new_key" >"$target_key"

    print_msg success "$(printf "$SUCCESS_SSL_UPDATED_FOR_DOMAIN" "$domain")"

    print_msg step "$STEP_NGINX_RELOADING"
    nginx_reload
    print_msg success "$SUCCESS_NGINX_RELOADED"
}
