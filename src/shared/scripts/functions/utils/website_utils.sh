# =====================================
# select_website: Display list of websites and allow user to select one
# Behavior:
#   - In TEST_MODE, auto-selects first site
#   - In interactive mode, prompts user to select
# Sets:
#   - global variables: SITE_DOMAIN, domain
# =====================================
select_website() {
    if [[ -z "$SITES_DIR" ]]; then
        echo -e "${RED}${CROSSMARK} SITES_DIR is not defined.${NC}"
        return 1
    fi

    local sites=()
    while IFS= read -r -d '' dir; do
        sites+=("$(basename "$dir")")
    done < <(find "$SITES_DIR" -mindepth 1 -maxdepth 1 -type d -print0)

    if [[ ${#sites[@]} -eq 0 ]]; then
        print_and_debug error "$ERROR_NO_WEBSITES_FOUND $SITES_DIR"
        return 1
    fi

    if [[ "$TEST_MODE" == true ]]; then
        SITE_DOMAIN="${TEST_SITE_DOMAIN:-${sites[0]}}"
        echo -e "${YELLOW}🧪 TEST_MODE: auto-selecting $SITE_DOMAIN${NC}"
    else
        echo -e "\n📄 Available websites:"
        for i in "${!sites[@]}"; do
            echo "  $((i + 1)). ${sites[$i]}"
        done

        SELECTED_WEBSITE=$(select_from_list "$PROMPT_WEBSITE_SELECT" "${sites[@]}")
        if [[ -z "$SELECTED_WEBSITE" ]]; then
            print_msg error "$ERROR_SELECT_OPTION_INVALID"
            return 1
        fi

        SITE_DOMAIN="$SELECTED_WEBSITE"

        # Check if the selected website exists
        if ! json_get_site_value "$SITE_DOMAIN" "DOMAIN" >/dev/null 2>&1; then
            print_msg error "$ERROR_WEBSITE_NOT_EXIST: $SITE_DOMAIN"
            return 1
        fi
        if [[ ! -d "$SITES_DIR/$SITE_DOMAIN" ]]; then
            print_msg error "$ERROR_WEBSITE_NOT_EXIST: $SITE_DOMAIN"
            return 1
        fi
    fi

    # Corrected assignment: no spaces around "=" in bash
    domain="$SITE_DOMAIN"
    #debug
    debug_log "[select_website] domain=$domain"
    print_and_debug info "$MSG_WEBSITE_SELECTED: $domain"
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

    if [[ -z "$domain" ]]; then
        print_msg error "❌ Missing domain parameter"
        return 1
    fi

    local site_dir="$SITES_DIR/$domain"
    local docker_compose_template="$TEMPLATES_DIR/docker-compose.yml.template"
    local docker_compose_target="$site_dir/docker-compose.yml"

    if ! is_file_exist "$docker_compose_template"; then
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
        db_container="$db_container" \
        envsubst <"$docker_compose_template" >"$docker_compose_target"

    print_msg success "$MSG_CREATED: $docker_compose_target"
}
