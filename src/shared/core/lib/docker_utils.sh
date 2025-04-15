#!/usr/bin/env bash

# ===========================
# 🔍 Check if container is running
# ===========================
is_container_running() {
  local all_running=true

  for container_name in "$@"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
      debug_log "[Docker] ✅ Container '$container_name' is running"
    else
      debug_log "[Docker] ❌ Container '$container_name' is NOT running"
      all_running=false
    fi
  done

  [[ "$all_running" == true ]]
}


# ===========================
# ❌ Remove container if running
# ===========================
remove_container() {
  local container_name="$1"
  if is_container_running "$container_name"; then
    print_msg info "$(printf "$INFO_DOCKER_REMOVING_CONTAINER" "$container_name")"
    docker rm -f "$container_name"
  fi
}


# ===========================
# ⚙️ Install Docker based on OS
# Supports:
#   - Debian/Ubuntu via apt
#   - CentOS/RedHat via yum
# ===========================
install_docker() {
  print_msg step "$STEP_DOCKER_INSTALL"

  if command -v apt-get &>/dev/null; then
    apt-get update
    apt-get install -y ca-certificates curl gnupg lsb-release
    mkdir -p /etc/apt/keyrings
    curl -fsSL "https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg" | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") $(lsb_release -cs) stable" \
      > /etc/apt/sources.list.d/docker.list
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

  elif command -v yum &>/dev/null; then
    yum install -y yum-utils
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

  else
    print_and_debug error "$ERROR_DOCKER_INSTALL_UNSUPPORTED_OS"
    exit 1
  fi
}

# ===========================
# 🧩 Install Docker Compose plugin (v2)
# Auto-detect OS and architecture
# ===========================
install_docker_compose() {
  print_msg step "$STEP_DOCKER_COMPOSE_INSTALL"

  local DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
  mkdir -p "$DOCKER_CONFIG/cli-plugins"

  local OS
  OS=$(uname -s | tr '[:upper:]' '[:lower:]')
  local ARCH
  ARCH=$(uname -m)

  case "$ARCH" in
    x86_64) ARCH="x86_64" ;;
    aarch64 | arm64) ARCH="aarch64" ;;
    *) print_and_debug error "$(printf "$ERROR_UNSUPPORTED_ARCH" "$ARCH")"; return 1 ;;
  esac

  local COMPOSE_URL="https://github.com/docker/compose/releases/download/v2.34.0/docker-compose-${OS}-${ARCH}"
  local DEST="$DOCKER_CONFIG/cli-plugins/docker-compose"

  print_msg info "➡️  $COMPOSE_URL"
  curl -SL "$COMPOSE_URL" -o "$DEST"
  chmod +x "$DEST"

  if docker compose version &>/dev/null; then
    print_msg success "$SUCCESS_DOCKER_COMPOSE_INSTALLED"
  else
    print_and_debug error "$ERROR_DOCKER_COMPOSE_INSTALL_FAILED"
  fi
}

# ===========================
# 🌀 Start Docker if not running
# macOS: use `open -a Docker`
# Linux: use `systemctl start docker`
# ===========================
start_docker_if_needed() {
  if ! docker info &>/dev/null; then
    print_msg warning "$WARNING_DOCKER_NOT_RUNNING"

    if [[ "$OSTYPE" == "darwin"* ]]; then
      # macOS: Start Docker Desktop in background
      open --background -a Docker

      local timeout=60
      local start_time
      start_time=$(date +%s)
      local current_time

      echo -n "Waiting for Docker"
      while ! docker info &>/dev/null; do
        echo -n "."
        sleep 0.5
        current_time=$(date +%s)
        if (( current_time - start_time > timeout )); then
          echo ""
          print_msg warning "Docker took too long to start, continuing anyway..."
          break
        fi
      done
      echo ""
    else
      # Linux: Start Docker service in background
      systemctl start docker &

      local counter=0
      echo -n "Waiting for Docker"
      while ! docker info &>/dev/null && [ $counter -lt 20 ]; do
        echo -n "."
        sleep 0.5
        counter=$((counter + 1))
      done
      echo ""
    fi
  else
    print_msg success "$SUCCESS_DOCKER_RUNNING"
  fi
}

# ===========================
# 👥 Ensure user is in Docker group (Linux only)
# macOS: No need to add group
# ===========================
check_docker_group() {
  if [[ "$(uname)" == "Darwin" ]]; then
    print_msg success "$INFO_DOCKER_GROUP_MAC"
  else
    if ! groups "$USER" | grep -q docker; then
      print_msg info "$(printf "$INFO_DOCKER_GROUP_ADDING" "$USER")"
      usermod -aG docker "$USER"
      print_msg success "$SUCCESS_DOCKER_GROUP_ADDED"
    fi
  fi
}

# ===========================
# 🔁 Execute a command inside the PHP container of a site
# Creates wp-cli cache directory for better compatibility
# Parameters:
#   $1 - domain
#   $2 - cmd
# ===========================
docker_exec_php() {
  local domain="$1"
  local cmd="$2"

  if [[ -z "$domain" || -z "$cmd" ]]; then
    print_and_debug error "❌ Missing parameters in docker_exec_php(domain, cmd)"
    return 1
  fi

  local container_php
  container_php=$(json_get_site_value "$domain" "CONTAINER_PHP")

  if [[ -z "$container_php" ]]; then
    print_and_debug error "❌ Cannot find CONTAINER_PHP for site: $domain"
    return 1
  fi

  docker exec -u "$PHP_USER" -i "$container_php" sh -c "mkdir -p /tmp/wp-cli-cache && export WP_CLI_CACHE_DIR='/tmp/wp-cli-cache' && $cmd"
  exit_if_error $? "$(printf "$ERROR_COMMAND_EXEC_FAILED" "$cmd")"
}

# ===========================
# 🧹 Remove core containers (NGINX, Redis)
# ===========================
remove_core_containers() {
  print_msg warning "$WARNING_REMOVE_CORE_CONTAINERS"
  docker rm -f "$NGINX_PROXY_CONTAINER" "$REDIS_CONTAINER" 2>/dev/null || true
}

# ===========================
# 🧹 Remove containers and volumes for all websites
# Uses get_site_list to iterate
# ===========================
remove_site_containers() {
  for site in $(get_site_list); do
    print_msg warning "$(printf "$WARNING_REMOVE_SITE_CONTAINERS" "$site")"
    docker rm -f "$site-php" "$site-mariadb" 2>/dev/null || true
    docker volume rm "${site}_db_data" 2>/dev/null || true
  done
}