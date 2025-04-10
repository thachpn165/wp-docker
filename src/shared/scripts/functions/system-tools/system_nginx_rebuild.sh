system_nginx_rebuild_logic() {
  print_msg step "$STEP_NGINX_REBUILD_START"

  # Stop & remove container
  run_in_dir "$NGINX_PROXY_DIR" docker stop "$NGINX_PROXY_CONTAINER"
  run_in_dir "$NGINX_PROXY_DIR" docker rm "$NGINX_PROXY_CONTAINER" > /dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    print_and_debug error "$ERROR_NGINX_STOP_REMOVE_FAILED"
    return 1
  fi

  # Detect image name from docker-compose
  IMAGE_NAME=$(grep -A 10 "$NGINX_PROXY_CONTAINER:" "$NGINX_PROXY_DIR/docker-compose.yml" | grep 'image:' | awk '{print $2}' | head -n 1)
  if [[ -z "$IMAGE_NAME" ]]; then
    print_and_debug error "$ERROR_NGINX_IMAGE_NAME_NOT_FOUND"
    return 1
  fi
  debug_log "[NGINX REBUILD] Detected image: $IMAGE_NAME"

  # Pull latest image
  run_cmd "docker pull $IMAGE_NAME" || return 1

  # Recreate container
  run_in_dir "$NGINX_PROXY_DIR" docker compose up -d $NGINX_PROXY_CONTAINER

  # Wait for container up to 30 seconds
  for i in {1..30}; do
    if is_container_running "$NGINX_PROXY_CONTAINER"; then
      print_msg success "$SUCCESS_NGINX_CONTAINER_STARTED"
      return 0
    fi
    sleep 1
  done

  print_and_debug error "$ERROR_NGINX_CONTAINER_START_FAILED"
  return 1
}