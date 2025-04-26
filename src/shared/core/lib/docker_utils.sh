#!/usr/bin/env bash

# ===========================
# ❌ Remove container if it is running
# Parameters:
#   $1 - Name of the container to remove
# Global variables used: None
# Result: None
# ===========================
remove_container() {
  local container_name="$1"
  if _is_container_running "$container_name"; then
    print_msg info "$(printf "$INFO_DOCKER_REMOVING_CONTAINER" "$container_name")"
    docker rm -f "$container_name"
  fi
}

# =====================================
# install_docker_almalinux: Install Docker on AlmaLinux/CentOS/RHEL 8
# No parameters
# =====================================
install_docker_almalinux() {
  local os_name=""
  local os_version=""

  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    os_name="${ID}"
    os_version="${VERSION_ID%%.*}"
  fi

  print_msg info "$STEP_DOKER_INSTALLING: ${os_name} (${os_version})"

  # Step 1: Remove old versions according to Docker documentation
  print_msg info "$INFO_DOCKER_REMOVE_OLD_VERSION"
  dnf remove -y docker \
    docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-engine \
    podman \
    runc &>/dev/null

  # Step 2: Install dnf-plugins-core
  print_msg info "dnf install dnf-plugins-core..."
  dnf -y install dnf-plugins-core &>/dev/null

  # Step 3: Set up Docker repository
  print_msg info "Setting up Docker repository..."
  dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo &>/dev/null

  # Step 4: Install Docker Engine
  print_msg info "Installing Docker Engine..."
  dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin &>/dev/null

  # Step 5: Start Docker
  print_msg info "Starting Docker service..."
  systemctl enable --now docker

  # Step 6: Verify installation
  print_msg info "Verifying installation..."
  if systemctl is-active docker >/dev/null 2>&1; then
    print_msg success "Docker service is running"

    # Try running hello-world container to confirm installation
    if docker run --rm hello-world &>/dev/null; then
      print_msg success "Docker installation verified successfully"
    else
      print_msg warning "Docker installed but hello-world test failed"
    fi
  else
    print_msg error "Docker service failed to start after installation"
    return 1
  fi

  return 0
}


# This function installs Docker on a general operating system using the official Docker installation script.
# It checks if Docker and Docker Compose are already installed, downloads and executes the installation script,
# verifies the installation, ensures the Docker service is running, and runs a hello-world container to confirm success.
install_docker_general_os() {
  local get_docker_url
  get_docker_url=$(network_check_http "https://get.docker.com")
  print_msg step "$STEP_DOCKER_INSTALL"

  # Check if Docker is already installed
  if command -v docker &>/dev/null; then
    if docker info &>/dev/null; then
      print_msg success "Docker is already installed and running"

      # Check Docker Compose
      if docker compose version &>/dev/null; then
        print_msg success "Docker Compose is already installed"
        return 0
      else
        print_msg warning "Docker Compose not found, but should be included with Docker installation"
      fi
      return 0
    fi
  fi

  print_msg info "$STEP_DOCKER_INSTALLING_USING_OFFICIAL_SCRIPT"

  # Create a temporary file to save the script
  local tmp_script=$(mktemp)

  # Download installation script from Docker
  if ! curl -fsSL "$get_docker_url" -o "$tmp_script"; then
    local formatted_error_url_failed
    formatted_error_url_failed="$(printf "$ERROR_DOCKER_GET_URL_FAILED" "$get_docker_url")"

    print_msg error "$formatted_error_url_failed"

    rm -f "$tmp_script"
    return 1
  fi

  # Grant execution permission to script
  chmod +x "$tmp_script"

  # Run installation script
  if sh "$tmp_script"; then
    print_msg success "Docker installed successfully"
  else
    print_msg error "Docker installation failed"
    rm -f "$tmp_script"
    return 1
  fi

  # Remove temporary script file
  rm -f "$tmp_script"

  # Verify installation
  if docker --version &>/dev/null; then
    print_msg success "Docker version: $(docker --version)"
  else
    print_msg error "Docker installation verification failed"
    return 1
  fi

  # Verify Docker Compose
  if docker compose version &>/dev/null; then
    print_msg success "Docker Compose is available"
  else
    print_msg warning "Docker Compose should have been installed with Docker but was not found"
  fi

  # Check if Docker service is running
  if ! systemctl is-active docker &>/dev/null; then
    print_msg info "Starting Docker service..."
    systemctl enable --now docker
  fi

  # Run hello-world container to confirm installation
  print_msg info "Verifying Docker installation with hello-world container..."
  if docker run --rm hello-world &>/dev/null; then
    print_msg success "Docker installation verified successfully"
  else
    print_msg warning "Docker installed but hello-world test failed"
  fi

  return 0
}

# =====================================
# install_docker: Install Docker, detect operating system and use appropriate method
# No parameters
# =====================================
install_docker() {
  # Detect operating system
  local os_name=""
  local os_version=""

  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    os_name="${ID}"
    os_version="${VERSION_ID%%.*}"
  fi

  # Check if it's AlmaLinux/CentOS/RHEL 8, use specific method
  if [[ "$os_name" == "almalinux" || "$os_name" == "centos" || "$os_name" == "rhel" ]] && [[ "$os_version" == "8" || "$os_version" == "9" ]]; then
    install_docker_almalinux # Install Docker using AlmaLinux method
    return $?
  fi

  # For other operating systems, use general installation method
  install_docker_general_os
}

# ===========================
# 🌀 Start Docker if it is not running
# Handles macOS and Linux separately.
# Parameters: None
# Global variables used: None
# Result: None
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

      print_msg step "$STEP_WAITING_DOCKER"
      while ! docker info &>/dev/null; do
        echo -n "."
        sleep 0.5
        current_time=$(date +%s)
        if ((current_time - start_time > timeout)); then
          echo ""
          print_msg warning "$WARNING_DOCKER_NOT_STARTED_AFTER_WAITING"
          break
        fi
      done
      echo ""
    else
      # Linux: Start Docker service in background
      if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: Start Docker Desktop in background
        open --background -a Docker
      else
        # Linux: Start Docker service in background
        systemctl start docker &
      fi

      local counter=0
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
# Checks and adds the user to the Docker group if not already a member.
# Parameters: None
# Global variables used: None
# Result: None
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
# Creates a wp-cli cache directory for better compatibility.
# Parameters:
#   $1 - domain
#   $2 - cmd
# Global variables used: PHP_USER
# Result: None
# ===========================
docker_exec_php() {
  local domain="$1"
  local cmd="$2"

  _is_missing_param "$domain" "--domain" || return 1
  _is_valid_domain "$domain" || return 1
  _is_missing_param "$cmd" "--cmd" || return 1

  local container_php
  container_php=$(json_get_site_value "$domain" "CONTAINER_PHP")

  if ! _is_container_running "$container_php"; then
    print_msg error "$ERROR_DOCKER_CONTAINER_NOT_RUNNING: $container_php"
    return 1
  fi

  docker exec -u "$PHP_USER" -i "$container_php" sh -c "mkdir -p /tmp/wp-cli-cache && export WP_CLI_CACHE_DIR='/tmp/wp-cli-cache' && $cmd"
  exit_if_error $? "$(printf "$ERROR_COMMAND_EXEC_FAILED" "$cmd")"
}

# ===========================
# 🧹 Remove core containers (NGINX, Redis)
# Removes core containers including NGINX and Redis.
# Parameters: None
# Global variables used: NGINX_PROXY_CONTAINER, REDIS_CONTAINER
# Result: None
# ===========================
remove_core_containers() {
  print_msg warning "$WARNING_REMOVE_CORE_CONTAINERS"
  docker rm -f "$NGINX_PROXY_CONTAINER" "$REDIS_CONTAINER" 2>/dev/null || true
}

# ===========================
# 🧹 Remove containers and volumes for all websites
# Uses get_site_list to iterate and remove site-specific containers and volumes.
# Parameters: None
# Global variables used: None
# Result: None
# ===========================
remove_site_containers() {
  for site in $(get_site_list); do
    print_msg step "$(printf "$STEP_REMOVE_SITE_CONTAINERS" "$site")"
    docker rm -f "$site-php" "$site-mariadb" 2>/dev/null || true
    docker volume rm "${site}_db_data" 2>/dev/null || true
  done
}
docker_volume_check_fastcgicache() {
  local volume_name="wpdocker_fastcgi_cache_data"

  if docker volume ls --format '{{.Name}}' | grep -q "^${volume_name}$"; then
    debug_log "[Docker] ✅ Volume '$volume_name' already exists."
  else
    print_msg step "$STEP_DOCKER_VOLUME_CREATING: $volume_name"
    docker volume create "$volume_name" >/dev/null
    print_msg success "$SUCCESS_DOCKER_VOLUME_CREATED: $volume_name"
  fi
}

# ===========================
# 📊 Check disk usage for host and Docker engine
# Parameters: None
# Global variables used: None
# Result: Displays disk usage summary
# ===========================
docker_check_disk_usage() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    disk_line=$(df -k / | awk 'NR==2')
    used_kb=$(echo "$disk_line" | awk '{print $3}')
    total_kb=$(echo "$disk_line" | awk '{print $2}')
  else
    # Linux
    disk_line=$(df -k --output=used,size / | tail -n1)
    used_kb=$(echo "$disk_line" | awk '{print $1}')
    total_kb=$(echo "$disk_line" | awk '{print $2}')
  fi

  used_bytes=$((used_kb * 1024))
  total_bytes=$((total_kb * 1024))

  # Analyze Docker disk usage
  docker_data=$(docker system df --format '{{json .}}')

  total_docker_bytes=0
  total_reclaimable_bytes=0

  while read -r line; do
    size=$(jq -r '.Size' <<<"$line")
    reclaimable=$(jq -r '.Reclaimable' <<<"$line" | awk '{print $1}')

    total_docker_bytes=$((total_docker_bytes + $(parse_size_to_bytes "$size")))
    total_reclaimable_bytes=$((total_reclaimable_bytes + $(parse_size_to_bytes "$reclaimable")))
  done <<<"$docker_data"

  # Display results
  print_msg title "WP Docker Disk Summary"
  echo "💻 Host Disk: Used $(format_bytes "$used_bytes") / Total $(format_bytes "$total_bytes")"
  echo "🐳 Docker Engine Usage: $(format_bytes "$total_docker_bytes")"
  echo "♻️  Reclaimable via Docker: $(format_bytes "$total_reclaimable_bytes")"
}

docker_check_and_start_container() {
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