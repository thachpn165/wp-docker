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
# 🚀 redis_start – Start Redis container if not running
# ============================================
# Description:
#   Starts the Redis container using docker-compose if it is not already running.
#
# Globals:
#   REDIS_CONTAINER
#   CORE_DIR
#
# Returns:
#   0 if started successfully or already running, 1 if docker-compose.yml not found
# ============================================
redis_start() {
    if redis_check_running; then
        print_msg success "Redis container \"$REDIS_CONTAINER\" is already running."
        return 0
    fi

    print_msg info "Starting Redis container: $REDIS_CONTAINER"

    local compose_file="$CORE_DIR/redis/docker-compose.yml"
    if [[ ! -f "$compose_file" ]]; then
        print_msg error "❌ Redis docker-compose.yml not found at: $compose_file"
        return 1
    fi

    docker compose -f "$compose_file" up -d

    print_msg success "✅ Redis container \"$REDIS_CONTAINER\" has been started."
}