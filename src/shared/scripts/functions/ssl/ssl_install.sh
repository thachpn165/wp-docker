#!/bin/bash
# ==================================================
# File: ssl_install.sh
# Description: Functions to manage SSL installation for WordPress sites, including generating 
#              self-signed certificates, issuing Let's Encrypt certificates, and managing 
#              manually provided certificates.
# Functions:
#   - ssl_prompt_general: Wrapper function to select a website and call SSL setup logic.
#       Parameters:
#           $1 - callback_function: Name of the logic function to call.
#   - ssl_prompt_letsencrypt: Prompt the user to install Let's Encrypt SSL for a selected site.
#       Parameters: None.
#   - ssl_logic_install_selfsigned: Generate a self-signed SSL certificate for a domain.
#       Parameters:
#           $1 - domain: Target domain.
#   - ssl_logic_install_letsencrypt: Issue SSL certificate using Let's Encrypt (certbot).
#       Parameters:
#           $1 - domain: Target domain.
#           $2 - email: Email for registration.
#           $3 - staging: Staging mode (true/false).
#   - ssl_logic_install_manual: Use manually provided SSL certificate and key.
#       Parameters:
#           $1 - domain: Target domain.
#           $2 - ssl_dir: Destination directory for SSL files.
#   - ssl_logic_edit_cert: Replace current SSL certificate with new pasted content.
#       Parameters:
#           $1 - domain: Target domain.
# ==================================================

ssl_prompt_general() {
    local callback_function="$1"
    local domain

    if ! website_get_selected domain; then
        return 1
    fi

    if [[ "$(type -t "$callback_function")" != "function" ]]; then
        print_and_debug error "Error: Function $callback_function does not exist"
        return 1
    fi

    "$callback_function" "$domain"
    return $?
}

ssl_prompt_letsencrypt() {
    local domain email
    if ! website_get_selected domain; then
        return 1
    fi

    email=$(get_input_or_test_value "$PROMPT_ENTER_EMAIL" "test@local")
    if [[ -z "$email" ]]; then
        print_and_debug error "$ERROR_MISSING_EMAIL"
        return 1
    fi

    ssl_cli_install_letsencrypt --domain="$domain" --email="$email"
}

ssl_logic_install_selfsigned() {
    local domain="$1"
    local ssl_dir="${TEST_MODE:+/tmp/test_ssl_directory}"
    [[ "$TEST_MODE" != true ]] && ssl_dir="$NGINX_PROXY_DIR/ssl"

    local cert_path="$ssl_dir/$domain.crt"
    local key_path="$ssl_dir/$domain.key"

    if [[ "$TEST_MODE" != true && ! -d "$PROJECT_DIR/sites/$domain" ]]; then
        print_and_debug error "$(printf "$ERROR_SITE_NOT_EXIST" "$domain")"
        return 1
    fi

    _is_directory_exist "$ssl_dir" || mkdir -p "$ssl_dir"

    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout "$key_path" \
        -out "$cert_path" \
        -subj "/C=VN/ST=HCM/L=HCM/O=WP-Docker/OU=Dev/CN=$domain"

    if [[ $? -eq 0 ]]; then
        nginx_reload || nginx_restart
        print_msg success "$(printf "$SUCCESS_SSL_SELF_SIGNED_GENERATED" "$domain")"
    else
        print_and_debug error "$ERROR_SSL_SELF_SIGNED_GENERATE_FAILED"
        return 1
    fi
}

ssl_logic_install_letsencrypt() {
    local domain="$1"
    local email="$2"
    local staging="$3"

    _is_valid_domain "$domain" || return 1
    _is_valid_email "$email" || return 1

    local ssl_dir=${SSL_DIR:-"$NGINX_PROXY_DIR/ssl"}
    local webroot="$SITES_DIR/$domain/wordpress"
    local certbot_data="$BASE_DIR/.certbot"

    if [[ ! -d "$webroot" ]]; then
        print_and_debug error "$ERROR_DIRECTORY_NOT_FOUND: $webroot"
        return 1
    fi

    mkdir -p "$ssl_dir" "$certbot_data"

    local certbot_args=(
        certonly --webroot -w /var/www/html -d "$domain"
        --non-interactive --agree-tos -m "$email"
    )
    [[ "$staging" == "true" ]] && certbot_args+=(--staging)

    docker run --rm \
        -v "$webroot:/var/www/html" \
        -v "$certbot_data:/etc/letsencrypt" \
        certbot/certbot "${certbot_args[@]}"

    local cert_path="$certbot_data/live/$domain/fullchain.pem"
    local key_path="$certbot_data/live/$domain/privkey.pem"

    if [[ ! -f "$cert_path" || ! -f "$key_path" ]]; then
        print_and_debug error "$(printf "$ERROR_SSL_CERT_NOT_FOUND" "$domain")"
        return 1
    fi

    copy_file "$cert_path" "$ssl_dir/$domain.crt"
    copy_file "$key_path" "$ssl_dir/$domain.key"

    nginx_reload || nginx_restart
    print_msg success "$(printf "$SUCCESS_SSL_INSTALLED" "$domain")"
}

ssl_logic_install_manual() {
    local domain="$1"
    local ssl_dir="$SSL_DIR"
    local target_crt="$ssl_dir/$domain.crt"
    local target_key="$ssl_dir/$domain.key"

    _is_valid_domain "$domain" || return 1

    _is_directory_exist "$ssl_dir" || mkdir -p "$ssl_dir"

    [[ ! -f "$target_crt" ]] && touch "$target_crt"
    [[ ! -f "$target_key" ]] && touch "$target_key"

    choose_editor || return

    "$EDITOR_CMD" "$target_crt"
    "$EDITOR_CMD" "$target_key"

    nginx_restart
    print_msg success "$SUCCESS_SSL_MANUAL_SAVED"
}

ssl_logic_edit_cert() {
    local domain="$1"
    local target_crt="$SSL_DIR/$domain.crt"
    local target_key="$SSL_DIR/$domain.key"

    if [[ ! -f "$target_crt" || ! -f "$target_key" ]]; then
        print_and_debug error "$(printf "$ERROR_SSL_CERT_NOT_FOUND_FOR_DOMAIN" "$domain")"
        return 1
    fi

    read -r new_cert
    read -r new_key

    echo "$new_cert" >"$target_crt"
    echo "$new_key" >"$target_key"

    nginx_reload || nginx_restart
    print_msg success "$(printf "$SUCCESS_SSL_UPDATED_FOR_DOMAIN" "$domain")"
}