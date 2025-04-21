website_list() {
    if [[ -z "$SITES_DIR" ]]; then
        print_and_debug error "SITES_DIR is not defined."
        return 1
    fi

    if [[ -z "$JSON_CONFIG_FILE" ]] || [[ ! -f "$JSON_CONFIG_FILE" ]]; then
        print_and_debug error "JSON_CONFIG_FILE is not defined or not found: $JSON_CONFIG_FILE"
        return 1
    fi

    local site_dirs=()
    local config_sites=()
    local valid_sites=()

    while IFS= read -r -d '' dir; do
        site_dirs+=("$(basename "$dir")")
    done < <(find "$SITES_DIR" -mindepth 1 -maxdepth 1 -type d -print0)

    mapfile -t config_sites < <(jq -r '.site | keys[]' "$JSON_CONFIG_FILE" 2>/dev/null)

    for site in "${config_sites[@]}"; do
        if [[ -d "$SITES_DIR/$site" ]]; then
            valid_sites+=("$site")
        else
            debug_log "[website_list] ⚠️ .config.json contain '$site' but not exist in $SITES_DIR"
        fi
    done

    for dir in "${site_dirs[@]}"; do
        if ! printf '%s\n' "${config_sites[@]}" | grep -qx "$dir"; then
            debug_log "[website_list] ⚠️ Folder '$dir' already exist $SITES_DIR but not in .config.json"
        fi
    done

    # 🟢 Chỉ in ra danh sách hợp lệ (dòng đơn)
    for site in "${valid_sites[@]}"; do
        echo "$site"
    done
}

website_prompt_select() {
    if [[ -z "$SITES_DIR" ]]; then
        print_msg error "SITES_DIR is not defined."
        return 1
    fi

    local sites=()
    while IFS= read -r site; do
        sites+=("$site")
    done < <(website_list)
    if [[ ${#sites[@]} -eq 0 ]]; then
        print_and_debug error "$ERROR_NO_WEBSITES_FOUND $SITES_DIR"
        return 1
    fi

    local selected=""
    if [[ "$TEST_MODE" == true ]]; then
        selected="${TEST_SITE_DOMAIN:-${sites[0]}}"
        echo -e "${YELLOW}🧪 TEST_MODE: auto-selecting $selected${NC}"
        echo "$selected"
        return 0
    fi

    while true; do
        echo -e "\n📄 Available websites:"
        for i in "${!sites[@]}"; do
            echo "  $((i + 1)). ${sites[$i]}"
        done

        selected=$(select_from_list "$PROMPT_WEBSITE_SELECT" "${sites[@]}")

        if [[ -z "$selected" ]]; then
            print_msg warning "$WARNING_SELECT_WEBSITE_REQUIRED"
            continue
        fi

        if ! printf '%s\n' "${sites[@]}" | grep -qx "$selected"; then
            print_msg error "$ERROR_WEBSITE_NOT_EXIST: $selected"
            continue
        fi

        break
    done

    debug_log "[website_prompt_select] selected=$selected"
    echo "$selected"
}

website_get_selected() {
    local __result_var="$1"
    local result tmp_output

    if [[ -z "$__result_var" ]]; then
        print_and_debug error "Missing variable name to store selected domain."
        return 1
    fi

    tmp_output="$(mktemp)"

    # 🟡 Gọi và kiểm tra status trả về
    if ! website_prompt_select > >(tee "$tmp_output"); then
        rm -f "$tmp_output"
        return 1
    fi

    result="$(tail -n 1 "$tmp_output")"
    rm -f "$tmp_output"

    if [[ -z "$result" ]]; then
        print_msg error "$ERROR_WEBSITE_NOT_SELECTED"
        return 1
    fi

    eval "$__result_var=\"\$result\""
    return 0
}
# =====================================
# website_generate_docker_compose: Generate docker-compose.yml for a website
# Parameters:
#   $1 - domain
# Behavior:
#   - Read site data from .config.json
#   - Use envsubst to populate a template into the site’s docker-compose.yml
# =====================================
website_generate_docker_compose() {
    local domain="$1"

    _is_missing_param "$domain" "--domain" || return 1
    _is_valid_domain "$domain" || return 1

    local site_dir="$SITES_DIR/$domain"
    local docker_compose_template="$TEMPLATES_DIR/docker-compose.yml.template"
    local docker_compose_target="$site_dir/docker-compose.yml"

    if ! _is_file_exist "$docker_compose_template"; then
        print_msg error "$MSG_NOT_FOUND: $docker_compose_template"
        return 1
    fi

    # Get data from .config.json
    local php_version
    local mysql_root_password
    local mysql_database
    local mysql_user
    local mysql_password
    local php_container
    local db_container

    php_version=$(json_get_value ".site[\"$domain\"].PHP_VERSION")
    mysql_root_password=$(json_get_value ".site[\"$domain\"].MYSQL_ROOT_PASSWORD")
    mysql_database=$(json_get_value ".site[\"$domain\"].MYSQL_DATABASE")
    mysql_user=$(json_get_value ".site[\"$domain\"].MYSQL_USER")
    mysql_password=$(json_get_value ".site[\"$domain\"].MYSQL_PASSWORD")
    php_container=$(json_get_value ".site[\"$domain\"].CONTAINER_PHP")
    db_container=$(json_get_value ".site[\"$domain\"].CONTAINER_DB")

    debug_log "[website_generate_docker_compose] domain=$domain"
    debug_log "[website_generate_docker_compose] php_container=$php_container"
    debug_log "[website_generate_docker_compose] db_container=$db_container"

    # Export temporary variables for envsubst
    DOMAIN="$domain" \
        PHP_VERSION="$php_version" \
        MYSQL_ROOT_PASSWORD="$mysql_root_password" \
        MYSQL_DATABASE="$mysql_database" \
        MYSQL_USER="$mysql_user" \
        MYSQL_PASSWORD="$mysql_password" \
        php_container="$php_container" \
        docker_network="$DOCKER_NETWORK" \
        db_container="$db_container" \
        envsubst <"$docker_compose_template" >"$docker_compose_target"

    print_msg success "$MSG_CREATED: $docker_compose_target"
}

generate_sitename_from_domain() {
    local domain="$1"
    _is_missing_param "$domain" "--domain" || return 1
    _is_valid_domain "$domain" || return 1
    # Cắt domain thành mảng theo dấu chấm
    IFS='.' read -ra parts <<<"$domain"
    local count="${#parts[@]}"

    # Loại bỏ phần đuôi cuối cùng (TLD) và đuôi phụ (ccTLD) nếu có
    local sitename_parts=("${parts[@]:0:count-2}")
    [[ ${#sitename_parts[@]} -eq 0 ]] && sitename_parts=("${parts[0]}")

    local sitename
    sitename=$(
        IFS=_
        echo "${sitename_parts[*]}"
    )
    echo "$sitename"
}
