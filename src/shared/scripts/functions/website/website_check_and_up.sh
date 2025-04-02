#!/bin/bash

website_check_and_up() {
    local site_dir site_name
    local php_container mariadb_container
    local started_any=false

    for site_dir in "$BASE_DIR/sites/"*/; do
        [ -d "$site_dir" ] || continue

        site_name=$(basename "$site_dir")
        php_container="${site_name}-php"
        mariadb_container="${site_name}-mariadb"

        _check_and_start_container "$php_container" "$site_name"
        _check_and_start_container "$mariadb_container" "$site_name"
    done

    if [ "$started_any" = true ]; then
        echo ""
        echo "${CHECKMARK} All stopped containers have been started (or attempted to start)."
    fi
}

_check_and_start_container() {
    local container_name="$1"
    local site_name="$2"
    local is_running

    # Do not display anything if the container does not exist
    if ! docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        return
    fi

    # Skip if the container is already running
    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        return
    fi

    echo ""
    echo "➡️  Site: $site_name"
    echo "   ⏳ Starting container $container_name..."
    docker start "$container_name" >/dev/null
    started_any=true

    # Check if the container is running (timeout 30s)
    for i in {1..30}; do
        sleep 1
        is_running=$(docker ps --format '{{.Names}}' | grep -c "^${container_name}$")
        if [ "$is_running" -eq 1 ]; then
            echo "   🚀 Container $container_name is now running."
            return
        fi
    done

    echo "   ${CROSSMARK} Container $container_name failed to start after 30s."
    echo "   📄 Showing last 20 lines of logs for $container_name:"
    docker logs --tail 20 "$container_name"
}
