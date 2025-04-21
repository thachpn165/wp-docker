# ============================================
# 🔧 redis_utils.sh – Redis container utilities
# ============================================
# Description:
#   Utility functions to check Redis container status and start it if not running.
#
# Globals:
#   REDIS_CONTAINER
#   CORE_DIR
# ============================================

# ============================================
# ✅ redis_check_running – Check if Redis container is running
# ============================================
# Description:
#   Returns 0 if the Redis container is currently running, 1 otherwise.
#
# Globals:
#   REDIS_CONTAINER
#
# Returns:
#   0 if running, non-zero if not
# ============================================
redis_check_running() {
    docker inspect -f '{{.State.Running}}' "$REDIS_CONTAINER" 2>/dev/null | grep -q true
}

# ============================================
# 🔁 redis_start – Start Redis container if not running
# ============================================
# Description:
#   - Starts the Redis container if not already running.
#   - If docker-compose.yml is missing, generates it from a template and replaces placeholders.
#
# Globals:
#   REDIS_CONTAINER       - Name of the Redis container
#   DOCKER_NETWORK        - Docker network to attach
#   CORE_DIR              - Core directory containing redis/
#   TEMPLATES_DIR         - Directory containing redis-docker-compose.yml.template
#
# Dependencies:
#   - redis_check_running
#   - print_msg
#   - sedi
# ============================================
redis_start() {
    if redis_check_running; then
        print_msg success "$SUCCESS_RED_is_container_running: $REDIS_CONTAINER"
        return 0
    fi

    print_msg step "$STEP_REDIS_STARTING_CONTAINER: $REDIS_CONTAINER"

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
    print_msg success "$SUCCESS_REDIS_STARTED" 
}
