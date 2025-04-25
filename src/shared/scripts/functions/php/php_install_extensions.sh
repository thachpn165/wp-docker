# ============================================
# 📦 PHP Extension Registry
# --------------------------------------------
# JSON list of available PHP extensions
# Each key is the internal name; title is for UI; function_name maps to the install function
# ============================================
readonly PHP_LIST_AVAILABLE_EXTENSIONS='{
  "ioncube_loader": {
    "title": "Ioncube Loader",
    "function_name": "ioncube_loader"
  }
}'

# ============================================
# 📋 php_prompt_install_extension
# --------------------------------------------
# Display a list of available extensions for user to choose
# Then calls the install logic for the selected extension
# ============================================
php_prompt_install_extension() {
    local domain
    if ! website_get_selected domain; then
        return 1
    fi
    _is_valid_domain "$domain" || return 1

    local keys selected_key
    local choice_list=()

    # Build list from JSON registry
    mapfile -t keys < <(jq -r 'keys[]' <<<"$PHP_LIST_AVAILABLE_EXTENSIONS")
    if [[ ${#keys[@]} -eq 0 ]]; then
        print_msg warning "$WARNING_PHP_NO_EXTENSION_AVAILABLE"
        return 1
    fi

    for key in "${keys[@]}"; do
        local title
        title=$(jq -r --arg key "$key" '.[$key].title' <<<"$PHP_LIST_AVAILABLE_EXTENSIONS")
        choice_list+=("$key" "$title")
    done

    # Show dialog for extension selection
    selected_key=$(dialog --stdout --menu "$PROMPT_PHP_CHOOSE_EXTENSION" 15 60 6 "${choice_list[@]}")
    if [[ -z "$selected_key" ]]; then
        print_msg cancel "$PROMPT_PHP_CHOOSE_EXTENSION"
        return 1
    fi

    # Call the installation logic
    php_logic_install_extension "$domain" "$selected_key"
}

# ============================================
# 🧠 php_logic_install_extension
# --------------------------------------------
# Wrapper to dynamically call the install function for a given extension
# ============================================
php_logic_install_extension() {
    local domain="$1"
    local extension="$2"
    _is_missing_param "$domain" "domain" || return 1
    _is_missing_param "$extension" "extension" || return 1

    local install_fn="php_install_extension_${extension//-/_}"
    if ! declare -F "$install_fn" >/dev/null; then
        local formatted_error_ext_not_supported
        formatted_error_ext_not_supported=$(printf "$ERROR_PHP_EXTENSION_NOT_SUPPORTED" "$extension")
        print_and_debug error "$formatted_error_ext_not_supported"
        return 1
    fi

    "$install_fn" "$domain"
}

# ============================================
# 🔐 php_install_extension_ioncube_loader
# --------------------------------------------
# Install Ioncube Loader for a PHP container, if compatible
# Checks architecture, PHP version, thread safety, and loader existence
# ============================================
php_install_extension_ioncube_loader() {
    local domain="$1"
    local php_container php_version loader_file loader_path site_php_ini zts_suffix arch
    php_container=$(json_get_site_value "$domain" "CONTAINER_PHP")
    php_version=$(docker exec -i "$php_container" php -r 'echo PHP_VERSION;' | cut -d. -f1,2)
    site_php_ini="$SITES_DIR/$domain/php/php.ini"

    # ✅ Check container architecture
    arch=$(docker exec -i "$php_container" uname -m | tr -d '\r')
    if [[ "$arch" != "x86_64" ]]; then
        local formatted_error_arch
        formatted_error_arch=$(printf "$ERROR_PHP_IONCUBE_NOT_SUPPORT_ARM" "$arch")
        print_msg error "$formatted_error_arch"
        return 0
    fi

    # ✅ Check if PHP uses Thread Safety (ZTS)
    if docker exec -i "$php_container" php -i | grep -q 'Thread Safety => enabled'; then
        zts_suffix="_ts"
        print_msg info "$INFO_PHP_CONTAINER_USE_ZTS"
    else
        zts_suffix=""
        print_msg info "$INFO_PHP_CONTAINER_USE_NTS"
    fi

    loader_file="ioncube_loader_lin_${php_version}${zts_suffix}.so"
    loader_path="/opt/bitnami/php/lib/php/extensions/${loader_file}"

    local formatted_check_compatible
    formatted_check_compatible=$(printf "$STEP_PHP_IONCUBE_CHECK_COMPATIBILITY" "$loader_file")
    print_msg step "$formatted_check_compatible"

    # ✅ Check if loader file exists
    if ! docker exec -i "$php_container" test -f "$loader_path"; then
        print_msg info "$INFO_PHP_IONCUBE_LOADER_NOT_FOUND"

        docker exec -u root -i "$php_container" bash -c "
          mkdir -p /tmp/ioncube &&
          curl -sSL -o /tmp/ioncube.tar.gz https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz &&
          tar -xzf /tmp/ioncube.tar.gz -C /tmp/ioncube &&
          tar -tzf /tmp/ioncube.tar.gz > /tmp/ioncube/filelist.txt
        "

        # ✅ Validate loader exists in archive
        if ! docker exec -i "$php_container" grep -q "ioncube/${loader_file}" /tmp/ioncube/filelist.txt; then
            local formatted_error_loader_not_found
            formatted_error_loader_not_found=$(printf "$WARNING_PHP_IONCUBE_NOT_COMPATIBLE" "$loader_file" "$php_version" "$zts_suffix")
            print_msg error "$formatted_error_loader_not_found"
            docker exec -u root -i "$php_container" rm -rf /tmp/ioncube /tmp/ioncube.tar.gz
            return 0
        fi

        docker exec -u root -i "$php_container" bash -c "
          cp /tmp/ioncube/ioncube/${loader_file} $loader_path &&
          chmod 755 $loader_path &&
          rm -rf /tmp/ioncube /tmp/ioncube.tar.gz
        "
    else
        print_msg info "✅ Ioncube loader already exists: $loader_path"
    fi

    # ✅ Confirm loader file really exists
    if ! docker exec -i "$php_container" test -f "$loader_path"; then
        local formatted_error_loader_not_found
        formatted_error_loader_not_found=$(printf "$ERROR_PHP_IONCUBE_LODER_NOT_FOUND" "$loader_path")
        print_msg error "$formatted_error_loader_not_found"
        return 1
    fi

    # ✅ Append to php.ini if not present
    if [[ ! -f "$site_php_ini" ]]; then
        print_and_debug error "$MSG_NOT_FOUND: $site_php_ini"
        return 1
    fi

    if ! grep -q "$loader_file" "$site_php_ini"; then
        printf "\nzend_extension=%s\n" "$loader_path" >>"$site_php_ini"
        print_msg success "$SUCCESS_PHP_IONCUBE_INI"
    else
        print_msg info "$WARNING_PHP_IONCUBE_ALREADY_INI"
    fi

    # ✅ Restart container
    docker restart "$php_container" >/dev/null
    local formatted_success_restart
    formatted_success_restart=$(printf "$SUCCESS_CONTAINER_RESTARTED" "$php_container")
    print_msg success "$formatted_success_restart"
    docker_exec_php docker_exec "$php_container" php -v
}

php_restore_enabled_extensions() {
    local domain="$1"
    _is_valid_domain "$domain" || return 1

    local php_ini="$SITES_DIR/$domain/php/php.ini"
    local active_extensions=()
    local extensions_to_restore=()

    print_msg step "$STEP_PHP_REINSTALLING_EXTENSIONS"

    if [[ ! -f "$php_ini" ]]; then
        print_msg warning "$WARNING_PHP_INI_NOT_FOUND"
        return 0
    fi

    # Extract all *.so from php.ini
    mapfile -t active_extensions < <(grep -E '^(zend_)?extension=' "$php_ini" | awk -F'=' '{print $2}' | xargs -n1 basename)

    for ext in "${active_extensions[@]}"; do
        [[ "$ext" == "imagick.so" ]] && continue

        # Convert .so name to extension ID
        local ext_id
        ext_id=$(echo "$ext" | sed -E 's/(ioncube_loader).*\.so/\1/' | tr -d '\r')

        # Only reinstall if supported
        if jq -e --arg key "$ext_id" 'has($key)' <<<"$PHP_LIST_AVAILABLE_EXTENSIONS" >/dev/null; then
            print_msg info "$(printf "$INFO_PHP_EXTENSION_REINSTALLING" "$ext_id")"
            php_logic_install_extension "$domain" "$ext_id"
        else
            print_msg warning "$(printf "$WARNING_PHP_EXTENSION_NOT_MANAGED" "$ext_id")"
        fi
    done
}
