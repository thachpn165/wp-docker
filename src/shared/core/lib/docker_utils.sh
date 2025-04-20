#!/usr/bin/env bash

# ===========================
# 🔍 Check if multiple containers are running
# Returns true if all specified containers are running.
# Parameters:
#   $@ - List of container names to check
# Global variables used: None
# Result: Returns true if all containers are running, false otherwise
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
# ❌ Remove container if it is running
# Parameters:
#   $1 - Name of the container to remove
# Global variables used: None
# Result: None
# ===========================
remove_container() {
  local container_name="$1"
  if is_container_running "$container_name"; then
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

  print_msg info "Installing Docker on ${os_name} ${os_version}..."

  # Step 1: Remove old versions according to Docker documentation
  print_msg info "Removing old versions..."
  dnf remove -y docker \
    docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-engine \
    podman \
    runc &>/dev/null || true

  # Step 2: Install dnf-plugins-core
  print_msg info "Installing dnf-plugins-core..."
  dnf -y install dnf-plugins-core

  # Step 3: Set up Docker repository
  print_msg info "Setting up Docker repository..."
  dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

  # Step 4: Install Docker Engine
  print_msg info "Installing Docker Engine..."
  dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

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

# =====================================
# install_docker: Install Docker, detect operating system and use appropriate method
# No parameters
# =====================================
install_docker() {
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
    print_msg info "Detected ${os_name} ${os_version}, using specialized installation method..."
    install_docker_almalinux
    return $?
  fi

  # For other operating systems, use get.docker.com script
  print_msg info "Installing Docker using official installation script..."

  # Create a temporary file to save the script
  local tmp_script=$(mktemp)

  # Download installation script from Docker
  if ! curl -fsSL https://get.docker.com -o "$tmp_script"; then
    print_msg error "Failed to download Docker installation script"
    rm -f "$tmp_script"
    return 1
  fi

  # Grant execution permission to script
  chmod +x "$tmp_script"

  # Run installation script
  print_msg info "Running Docker installation script..."
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

      echo -n "Waiting for Docker"
      while ! docker info &>/dev/null; do
        echo -n "."
        sleep 0.5
        current_time=$(date +%s)
        if ((current_time - start_time > timeout)); then
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

  if [[ -z "$domain" || -z "$cmd" ]]; then
    print_and_debug error "$ERROR_MISSING_PARAM: --domain or --cmd"
    return 1
  fi

  local container_php
  container_php=$(json_get_site_value "$domain" "CONTAINER_PHP")

  if [[ -z "$container_php" ]]; then
    print_and_debug error "$ERROR_DOCKER_CONTAINER_DB_NOT_DEFINED: $domain"
    return 1
  fi

  if ! is_container_running "$container_php"; then
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
    print_msg warning "$(printf "$WARNING_REMOVE_SITE_CONTAINERS" "$site")"
    docker rm -f "$site-php" "$site-mariadb" 2>/dev/null || true
    docker volume rm "${site}_db_data" 2>/dev/null || true
  done
}
docker_volume_check_fastcgicache() {
  local volume_name="wpdocker_fastcgi_cache_data"

  if docker volume ls --format '{{.Name}}' | grep -q "^${volume_name}$"; then
    debug_log "[Docker] ✅ Volume '$volume_name' already exists."
  else
    print_msg info "📦 Creating Docker volume: $volume_name"
    docker volume create "$volume_name" >/dev/null
    print_msg success "✅ Docker volume '$volume_name' has been created."
  fi
}