system_nginx_rebuild_logic() {
  run_in_dir "$NGINX_PROXY_DIR" docker stop "$NGINX_PROXY_CONTAINER" && docker rm "$NGINX_PROXY_CONTAINER" > /dev/null 2>&1
  exit_if_error $? "Failed to stop and remove NGINX Proxy container."

  IMAGE_NAME=$(grep -A 10 "$NGINX_PROXY_CONTAINER:" "$NGINX_PROXY_DIR/docker-compose.yml" | grep 'image:' | awk '{print $2}' | head -n 1)
  if [[ -z "$IMAGE_NAME" ]]; then
    return 1
  fi

  run_in_dir "$NGINX_PROXY_DIR" docker pull "$IMAGE_NAME"

  run_in_dir "$NGINX_PROXY_DIR" docker compose up -d nginx-proxy

  for i in {1..30}; do
    if is_container_running "$NGINX_PROXY_CONTAINER"; then
      break
    fi
    sleep 1
  done

  if ! is_container_running "$NGINX_PROXY_CONTAINER"; then
    return 1
  fi
}
