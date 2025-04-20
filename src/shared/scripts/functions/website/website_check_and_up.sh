#!/bin/bash

website_check_and_up() {
    local domain php_container
    local started_any=false

    mapfile -t domains < <(website_list)
    if [[ ${#domains[@]} -eq 0 ]]; then
        print_msg warning "⚠️ No valid websites found in $SITES_DIR"
        return 0
    fi

    for domain in "${domains[@]}"; do
        php_container=$(json_get_site_value "$domain" "CONTAINER_PHP")
        _check_and_start_container "$php_container" "$domain"
    done

    if [[ "$started_any" == true ]]; then
        echo ""
        echo "${CHECKMARK} All stopped containers have been started (or attempted to start)."
    fi
}

_check_and_start_container() {
    local container_name="$1"
    local domain="$2"
    local is_running

    _is_missing_param "$container_name" "--container_name" || return 1
    _is_missing_param "$domain" "--domain" || return 1
    _is_valid_domain "$domain" || return 1
    if [[ -z "$container_name" ]]; then
        print_and_debug warning "⚠️  Skipped empty container for domain: $domain"
        return
    fi

    # Do not display anything if the container does not exist
    if ! docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        return
    fi

    # Skip if the container is already running
    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        return
    fi

    echo ""
    echo "➡️  Site: $domain"
    echo "   ⏳ Starting container $container_name..."
    docker start "$container_name" >/dev/null
    started_any=true

    for _ in {1..30}; do
        sleep 1
        is_running=$(docker ps --format '{{.Names}}' | grep -c "^${container_name}$")
        if [[ "$is_running" -eq 1 ]]; then
            echo "   🚀 Container $container_name is now running."
            return
        fi
    done

    echo "   ${CROSSMARK} Container $container_name failed to start after 30s."
    echo "   📄 Showing last 20 lines of logs for $container_name:"
    docker logs --tail 20 "$container_name"
}