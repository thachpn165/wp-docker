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

# ===========================
# ⚙️ Install Docker based on OS
# Supports:
#   - Debian/Ubuntu via apt
#   - CentOS/RedHat via yum
# Parameters: None
# Global variables used: None
# Result: None
# ===========================
install_docker() {
  print_msg step "$STEP_DOCKER_INSTALL"

  # Kiểm tra hệ điều hành
  local os_name=""
  local os_version=""

  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    os_name="${ID}"
    os_version="${VERSION_ID%%.*}"
  fi

  print_msg info "Detected OS: ${os_name} ${os_version}"

  # Kiểm tra Docker đã được cài đặt chưa
  if command -v docker &>/dev/null; then
    if docker info &>/dev/null; then
      print_msg success "Docker is already installed and running"

      # Cài đặt docker-compose nếu cần
      if ! docker compose version &>/dev/null; then
        install_docker_compose
      else
        print_msg success "Docker Compose is already installed"
      fi

      return 0
    else
      print_msg warning "Docker is installed but not running. Attempting to start service..."
      systemctl enable docker
      systemctl start docker

      # Kiểm tra lại
      if docker info &>/dev/null; then
        print_msg success "Docker service started successfully"
        return 0
      else
        print_msg warning "Docker service failed to start. Reinstalling..."
      fi
    fi
  fi

  # Dừng và vô hiệu hóa podman nếu đang chạy (có thể gây xung đột với Docker)
  if command -v podman &>/dev/null; then
    print_msg warning "Podman detected. Disabling before installing Docker..."
    systemctl disable --now podman.socket &>/dev/null || true
  fi

  if [[ "$os_name" == "almalinux" || "$os_name" == "centos" || "$os_name" == "rhel" ]] && [[ "$os_version" == "8" ]]; then
    print_msg info "Installing Docker on ${os_name} ${os_version}..."

    # Chạy update hệ thống trước
    dnf update --nogpgcheck -y

    # Xóa triệt để các phiên bản Docker cũ và Podman theo tài liệu chính thức
    print_msg info "Removing conflicting packages..."
    dnf remove -y docker \
      docker-client \
      docker-client-latest \
      docker-common \
      docker-latest \
      docker-latest-logrotate \
      docker-logrotate \
      docker-engine \
      podman \
      podman-docker \
      buildah \
      skopeo \
      runc \
      containerd \
      containernetworking-plugins &>/dev/null || true

    # Cài đặt dnf-plugins-core
    print_msg info "Installing dnf-plugins-core..."
    dnf -y install dnf-plugins-core

    # Cài đặt các gói cần thiết khác
    print_msg info "Installing other prerequisites..."
    dnf install -y device-mapper-persistent-data lvm2

    # Thêm repo Docker CE
    print_msg info "Adding Docker repository..."
    dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo

    # Khắc phục vấn đề modular filtering cho container-selinux
    print_msg info "Enabling modules required for Docker..."
    dnf module disable -y container-tools

    # Cài đặt container-selinux từ CentOS repository
    print_msg info "Installing container-selinux package..."
    dnf install -y --nogpgcheck http://mirror.centos.org/centos/8-stream/AppStream/x86_64/os/Packages/container-selinux-2.167.0-1.module_el8.5.0+911+f19012f9.noarch.rpm || true

    # Cài đặt Docker với các flag cần thiết
    print_msg info "Installing Docker CE..."
    dnf install -y --nobest --allowerasing --nogpgcheck docker-ce docker-ce-cli containerd.io

    # Không sử dụng --replace vì không được hỗ trợ
    # Thay vì vậy, đảm bảo các gói đã được cài đặt đúng
    print_msg info "Verifying Docker installation..."
    dnf install -y --nogpgcheck docker-ce

    # Enable và start dịch vụ Docker
    print_msg info "Enabling and starting Docker service..."
    systemctl enable docker
    systemctl start docker

    # Kiểm tra trạng thái Docker
    if systemctl is-active docker >/dev/null 2>&1; then
      print_msg success "Docker service is running"
    else
      print_msg warning "Docker service is not running. Attempting to start..."
      systemctl start docker
    fi

    # Cài đặt Docker Compose v2 từ GitHub
    install_docker_compose

  elif command -v apt-get &>/dev/null; then
    print_msg info "Installing Docker on Debian/Ubuntu..."
    apt-get update
    apt-get install -y ca-certificates curl gnupg lsb-release

    # Thêm Docker repository
    mkdir -p /etc/apt/keyrings
    curl -fsSL "https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg" | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") $(lsb_release -cs) stable" \
      >/etc/apt/sources.list.d/docker.list

    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

  elif command -v yum &>/dev/null; then
    print_msg info "Installing Docker using yum..."
    yum install -y yum-utils
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    yum install -y docker-ce docker-ce-cli containerd.io

    systemctl enable docker
    systemctl start docker

    install_docker_compose
  else
    print_and_debug error "$ERROR_DOCKER_INSTALL_UNSUPPORTED_OS"
    exit 1
  fi

  # Kiểm tra lại cài đặt
  if docker info &>/dev/null; then
    print_msg success "Docker installed and running successfully"
    return 0
  else
    print_and_debug error "Docker installation failed or service not running"
    exit 1
  fi
}

# Hàm cài đặt Docker Compose
install_docker_compose() {
  print_msg info "Installing Docker Compose..."

  # Xóa phiên bản cũ nếu có
  if [[ -f /usr/local/bin/docker-compose ]]; then
    print_msg info "Removing old docker-compose binary..."
    rm -f /usr/local/bin/docker-compose
  fi

  # Kiểm tra xem docker compose plugin đã được cài đặt chưa
  if docker compose version &>/dev/null; then
    print_msg success "Docker Compose plugin is already installed"
    return 0
  fi

  # Xác định phiên bản mới nhất và kiến trúc
  print_msg info "Determining latest Docker Compose version..."
  LATEST_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
  COMPOSE_VERSION=${COMPOSE_VERSION:-$LATEST_COMPOSE_VERSION}

  # Xác định kiến trúc hệ thống
  OS_TYPE=$(uname -s | tr '[:upper:]' '[:lower:]')
  ARCH=$(uname -m)

  # Xử lý kiến trúc đặc biệt
  if [[ "$ARCH" == "x86_64" ]]; then
    ARCH="x86_64"
  elif [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    ARCH="aarch64"
  elif [[ "$ARCH" == "armv7l" ]]; then
    ARCH="armv7"
  fi

  COMPOSE_ARCH="${OS_TYPE}-${ARCH}"

  print_msg info "Installing Docker Compose ${COMPOSE_VERSION} for ${COMPOSE_ARCH}..."

  # Tạo thư mục plugins
  mkdir -p /usr/local/lib/docker/cli-plugins/

  # Tải xuống Docker Compose
  DOWNLOAD_URL="https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-${COMPOSE_ARCH}"
  print_msg info "Downloading from: ${DOWNLOAD_URL}"

  if ! curl -sSL --fail "$DOWNLOAD_URL" -o /usr/local/lib/docker/cli-plugins/docker-compose; then
    print_msg error "Failed to download Docker Compose. Check URL: ${DOWNLOAD_URL}"
    return 1
  fi

  # Cấp quyền thực thi
  chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

  # Tạo symlink cho khả năng tương thích ngược
  ln -sf /usr/local/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose

  # Trong một số trường hợp, đường dẫn plugin có thể khác
  if [[ -d /usr/libexec/docker/cli-plugins ]]; then
    print_msg info "Creating additional symlink for some distributions..."
    mkdir -p /usr/libexec/docker/cli-plugins
    ln -sf /usr/local/lib/docker/cli-plugins/docker-compose /usr/libexec/docker/cli-plugins/docker-compose
  fi

  # Kiểm tra cài đặt
  if docker compose version &>/dev/null; then
    INSTALLED_VERSION=$(docker compose version --short)
    print_msg success "Docker Compose ${INSTALLED_VERSION} installed successfully"
    return 0
  else
    # Thử kiểm tra bằng đường dẫn trực tiếp
    if /usr/local/bin/docker-compose version &>/dev/null; then
      INSTALLED_VERSION=$(/usr/local/bin/docker-compose version --short)
      print_msg success "Docker Compose ${INSTALLED_VERSION} installed as standalone binary"
      return 0
    else
      print_msg error "Docker Compose installation failed. Please check logs."
      return 1
    fi
  fi
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
