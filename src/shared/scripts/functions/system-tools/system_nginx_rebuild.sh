# =====================================
# system_logic_nginx_rebuild: Rebuild the NGINX proxy container
# Steps:
#   - Stop and remove current container
#   - Detect and pull the latest image from docker-compose
#   - Recreate the container
#   - Wait for container to start (max 30s)
# Requires:
#   - $NGINX_PROXY_DIR, $NGINX_PROXY_CONTAINER
# =====================================
system_logic_nginx_rebuild() {
  print_msg step "$STEP_NGINX_REBUILD_START"

  # Stop and remove the container
  run_in_dir "$NGINX_PROXY_DIR" docker stop "$NGINX_PROXY_CONTAINER"
  run_in_dir "$NGINX_PROXY_DIR" docker rm "$NGINX_PROXY_CONTAINER" > /dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    print_and_debug error "$ERROR_NGINX_STOP_REMOVE_FAILED"
    return 1
  fi

  # Detect image name from docker-compose file
  IMAGE_NAME=$(grep -A 10 "$NGINX_PROXY_CONTAINER:" "$NGINX_PROXY_DIR/docker-compose.yml" | grep 'image:' | awk '{print $2}' | head -n 1)
  if [[ -z "$IMAGE_NAME" ]]; then
    print_and_debug error "$ERROR_NGINX_IMAGE_NAME_NOT_FOUND"
    return 1
  fi
  debug_log "[NGINX REBUILD] Detected image: $IMAGE_NAME"

  # Pull the latest image
  run_cmd "docker pull $IMAGE_NAME" || return 1

  # Recreate the container using Docker Compose
  run_in_dir "$NGINX_PROXY_DIR" docker compose up -d $NGINX_PROXY_CONTAINER

  # Wait up to 30 seconds for container to become active
  for i in {1..30}; do
    debug_log "[NGINX REBUILD] Attempt $i to check if container is running"
    if _is_container_running "$NGINX_PROXY_CONTAINER"; then
      print_msg success "$SUCCESS_NGINX_CONTAINER_STARTED"
      return 0
    fi
    sleep 1
  done

  print_and_debug error "$ERROR_NGINX_CONTAINER_START_FAILED"
  return 1
}