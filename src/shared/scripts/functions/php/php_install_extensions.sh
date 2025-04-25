readonly PHP_LIST_AVAILABLE_EXTENSIONS='{
  "ioncube_loader": {
    "title": "Ioncube Loader",
    "function_name": "ioncube_loader"
  }
}'

php_prompt_install_extension() {
    local domain
    if ! website_get_selected domain; then
        return 1
    fi
    _is_valid_domain "$domain" || return 1

    local keys selected_key
    local choice_list=()

    # Tạo danh sách hiển thị từ JSON
    mapfile -t keys < <(jq -r 'keys[]' <<<"$PHP_LIST_AVAILABLE_EXTENSIONS")
    if [[ ${#keys[@]} -eq 0 ]]; then
        print_msg warning "⚠️ Không có extension nào khả dụng để cài đặt."
        return 1
    fi

    for key in "${keys[@]}"; do
        local title
        title=$(jq -r --arg key "$key" '.[$key].title' <<<"$PHP_LIST_AVAILABLE_EXTENSIONS")
        choice_list+=("$key" "$title")
    done

    # Hiển thị danh sách cho người dùng chọn
    selected_key=$(dialog --stdout --menu "📦 Chọn extension PHP để cài đặt" 15 60 6 "${choice_list[@]}")
    if [[ -z "$selected_key" ]]; then
        print_msg warning "⛔ Bạn đã huỷ thao tác cài đặt extension."
        return 1
    fi

    # Gọi hàm logic đã có
    php_logic_install_extension "$domain" "$selected_key"
}

php_logic_install_extension() {
    local domain="$1"
    local extension="$2"
    _is_missing_param "$domain" "domain" || return 1
    _is_missing_param "$extension" "extension" || return 1

    local install_fn="php_install_extension_${extension//-/_}"
    if ! declare -F "$install_fn" >/dev/null; then
        print_and_debug error "❌ Extension '$extension' is not supported."
        return 1
    fi

    "$install_fn" "$domain"
}

php_install_extension_ioncube_loader() {
    local domain="$1"
    local php_container php_version loader_file loader_path site_php_ini zts_suffix arch
    php_container=$(json_get_site_value "$domain" "CONTAINER_PHP")
    php_version=$(docker exec -i "$php_container" php -r 'echo PHP_VERSION;' | cut -d. -f1,2)
    site_php_ini="$SITES_DIR/$domain/php/php.ini"

    # ✅ Kiểm tra kiến trúc hệ thống
    arch=$(docker exec -i "$php_container" uname -m | tr -d '\r')

    if [[ "$arch" != "x86_64" ]]; then
        print_msg warning "⚠️ Không thể cài đặt Ioncube Loader: kiến trúc CPU của container là '$arch' (chỉ hỗ trợ x86_64)"
        return 0
    fi

    # ✅ Kiểm tra ZTS (Thread Safety)
    if docker exec -i "$php_container" php -i | grep -q 'Thread Safety => enabled'; then
        zts_suffix="_ts"
        print_msg info "ℹ️ PHP container sử dụng Thread Safety (ZTS)"
    else
        zts_suffix=""
        print_msg info "ℹ️ PHP container KHÔNG sử dụng Thread Safety (NTS)"
    fi

    loader_file="ioncube_loader_lin_${php_version}${zts_suffix}.so"
    loader_path="/opt/bitnami/php/lib/php/extensions/${loader_file}"

    print_msg step "📦 Đang kiểm tra khả năng cài đặt Ioncube Loader ($loader_file)..."

    docker exec -u root -i "$php_container" bash -c "
    mkdir -p /tmp/ioncube &&
    curl -sSL -o /tmp/ioncube.tar.gz https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz &&
    tar -xzf /tmp/ioncube.tar.gz -C /tmp/ioncube &&
    tar -tzf /tmp/ioncube.tar.gz > /tmp/ioncube/filelist.txt
  "

    if ! docker exec -i "$php_container" grep -q "ioncube/${loader_file}" /tmp/ioncube/filelist.txt; then
        print_msg warning "⚠️ Không tìm thấy file Ioncube Loader phù hợp: $loader_file (PHP $php_version, ZTS=${zts_suffix:+có})"
        docker exec -u root -i "$php_container" rm -rf /tmp/ioncube /tmp/ioncube.tar.gz
        return 0
    fi

    docker exec -u root -i "$php_container" bash -c "
    cp /tmp/ioncube/ioncube/${loader_file} $loader_path &&
    chmod 755 $loader_path &&
    rm -rf /tmp/ioncube /tmp/ioncube.tar.gz
  "

    if ! docker exec -i "$php_container" test -f "$loader_path"; then
        print_msg warning "⚠️ Không tìm thấy file loader thực tế sau khi cài đặt: $loader_path"
        return 1
    fi

    if [[ ! -f "$site_php_ini" ]]; then
        print_and_debug error "❌ Không tìm thấy file PHP cấu hình: $site_php_ini"
        return 1
    fi

    if ! grep -q "$loader_file" "$site_php_ini"; then
        printf "\nzend_extension=%s\n" "$loader_path" >>"$site_php_ini"
        print_msg success "✅ Đã thêm cấu hình Ioncube vào php.ini"
    else
        print_msg info "ℹ️ Cấu hình Ioncube đã tồn tại trong php.ini"
    fi

    docker restart "$php_container" >/dev/null
    print_msg success "✅ Đã restart container PHP: $php_container"
}
