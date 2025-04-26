# ============================================
# File: redis_utils.sh
# Description: Utility functions to manage Redis containers in a Docker environment.
# Functions:
#   - redis_check_running: Check if the Redis container is running.
#       Parameters:
#           None
#       Globals:
#           REDIS_CONTAINER
#       Returns:
#           0 if running, non-zero if not.
#   - core_redis_start: Start the Redis container if not running.
#       Parameters:
#           None
#       Globals:
#           REDIS_CONTAINER
#           DOCKER_NETWORK
#           CORE_DIR
#           TEMPLATES_DIR
#       Dependencies:
#           redis_check_running, print_msg, sedi
# ============================================

redis_check_running() {
    docker inspect -f '{{.State.Running}}' "$REDIS_CONTAINER" 2>/dev/null | grep -q true
}

core_redis_start() {
    if redis_check_running; then
        print_msg success "$SUCCESS_REDIS_RUNNING: $REDIS_CONTAINER"
        return 0
    fi

    print_msg step "$SUCCESS_CORE_REDIS_STARTED: $REDIS_CONTAINER"

    local compose_dir="$CORE_DIR/redis"
    local compose_file="$compose_dir/docker-compose.yml"
    local template_file="$TEMPLATES_DIR/redis-docker-compose.yml.template"

    # Generate docker-compose.yml if missing
    if [[ ! -f "$compose_file" ]]; then
        print_msg warning "$WARNING_REDIS_DOCKER_COMPOSE_NOT_FOUND: $compose_file"
        print_msg info "$INFO_REDIS_GENERATING_DOCKER_COMPOSE"

        mkdir -p "$compose_dir"

        if [[ ! -f "$template_file" ]]; then
            print_and_debug error "Template not found: $template_file"
            return 1
        fi

        cp "$template_file" "$compose_file"

        # Replace placeholders using sedi
        sedi "s|\${redis_container}|$REDIS_CONTAINER|g" "$compose_file"
        sedi "s|\${docker_network}|$DOCKER_NETWORK|g" "$compose_file"

        print_msg success "$SUCCESS_REDIS_COMPOSE_GENERATED: $compose_file"
    fi

    docker compose -f "$compose_file" up -d
    print_msg success "$SUCCESS_CORE_REDIS_STARTED: $REDIS_CONTAINER"
}