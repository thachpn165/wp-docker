redis_check_running() {
    docker inspect -f '{{.State.Running}}' "$REDIS_CONTAINER" 2>/dev/null | grep -q true
}

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