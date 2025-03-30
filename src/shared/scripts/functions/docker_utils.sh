#!/bin/bash

# Check if a container is running
is_container_running() {
    local container_name="$1"

    # Trong môi trường test, luôn coi như container đã chạy
    if [[ "$TEST_MODE" == true ]]; then
        echo "[MOCK is_container_running] TEST_MODE=true → return 0" >&2
        return 0
    fi

    # Kiểm tra thực tế trong môi trường thật
    docker ps --format '{{.Names}}' | grep -q "^${container_name}$"
}


# Check if a Docker volume exists
is_volume_exist() {
    local volume_name="$1"
    
    # Mock when in TEST_MODE
    if [[ "$TEST_MODE" == true ]]; then
        return 0  # volume always exists in TEST_MODE
    fi

    # Check volume when not in TEST_MODE
    docker volume ls --format '{{.Name}}' | grep -q "^${volume_name}$"
    #run_unless_test docker volume ls --format '{{.Name}}' | grep -q "^${volume_name}$"
}

# Remove container if it's running
remove_container() {
    local container_name="$1"
    
    # Mock when in TEST_MODE
    if [[ "$TEST_MODE" == true ]]; then
        echo "🧪 Skipping container removal in TEST_MODE: $container_name"
        return 0  # do nothing in TEST_MODE
    fi

    # Perform container removal when not in TEST_MODE
    if is_container_running "$container_name"; then
        echo "🛑 Stopping and removing container: $container_name..."
        docker rm -f "$container_name"
    fi
}

# Remove volume if it exists
remove_volume() {
    local volume_name="$1"
    if is_volume_exist "$volume_name"; then
        echo "🗑️ Removing volume: $volume_name..."
        docker volume rm "$volume_name"
    fi
}

# ✅ Function to automatically install Docker
install_docker() {
    echo -e "${YELLOW}🔧 Installing Docker...${NC}"
    if [ -x "$(command -v apt-get)" ]; then
         apt-get update
         apt-get install -y ca-certificates curl gnupg lsb-release
         mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg | \
             gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
          https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") \
          $(lsb_release -cs) stable" | \
           tee /etc/apt/sources.list.d/docker.list > /dev/null
         apt-get update
         apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    elif [ -x "$(command -v yum)" ]; then
         yum install -y yum-utils
         yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
         yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    else
        echo -e "${RED}❌ This operating system is not supported for automatic Docker installation.${NC}"
        exit 1
    fi
}

# ✅ Function to install Docker Compose from GitHub release
install_docker_compose() {
    echo -e "${YELLOW}📦 Installing Docker Compose plugin...${NC}"

    DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
    mkdir -p "$DOCKER_CONFIG/cli-plugins"

    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)

    # Normalize architecture
    case "$ARCH" in
        x86_64) ARCH="x86_64" ;;
        aarch64 | arm64) ARCH="aarch64" ;;
        *) echo "❌ Unsupported machine architecture: $ARCH" && return 1 ;;
    esac

    COMPOSE_URL="https://github.com/docker/compose/releases/download/v2.34.0/docker-compose-${OS}-${ARCH}"
    DEST="$DOCKER_CONFIG/cli-plugins/docker-compose"

    echo "➡️  Downloading from: $COMPOSE_URL"
    curl -SL "$COMPOSE_URL" -o "$DEST"
    chmod +x "$DEST"

    if docker compose version &>/dev/null; then
        echo -e "${GREEN}✅ Docker Compose has been installed successfully.${NC}"
    else
        echo -e "${RED}❌ Docker Compose installation failed. Please check manually.${NC}"
    fi
}

# ✅ Function to check if Docker is running
start_docker_if_needed() {
    if (! docker stats --no-stream &> /dev/null); then
        echo -e "${YELLOW}🌀 Docker is not running. Starting Docker...${NC}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            open --background -a Docker
            while ! docker system info > /dev/null 2>&1; do
                echo -n "."
                sleep 1
            done
            echo " ✅"
        else
             systemctl start docker
        fi
    else
        echo -e "${GREEN}✅ Docker is running.${NC}"
    fi
}

# ✅ Function to check & add user to docker group if needed
check_docker_group() {
    # Check operating system
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS doesn't require user to be in docker group
        echo -e "${GREEN}✅ On macOS, no need to add user to docker group.${NC}"
    else
        # Linux - check and add user to docker group if needed
        if ! groups "$USER" | grep -q docker; then
            echo -e "${YELLOW}➕ Adding user '$USER' to docker group...${NC}"
             usermod -aG docker "$USER"
            echo -e "${GREEN}✅ User has been added to docker group. Please logout/login for changes to take effect.${NC}"
        fi
    fi
}

# 🧩 Quick docker exec function
docker_exec_php() {
    docker exec -u "$PHP_USER" -i "$PHP_CONTAINER" sh -c "$1"
}

# If this script is called directly, execute the corresponding function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        is_docker_running) is_docker_running ;;
        check_docker_status) check_docker_status ;;
        *) echo -e "${RED}❌ Invalid command!${NC} Usage: $0 {is_docker_running|check_docker_status}" ;;
    esac
fi

# 🧹 Remove core containers including nginx proxy and redis-cache
remove_core_containers() {
  echo -e "${YELLOW}🧹 Removing containers $NGINX_PROXY_CONTAINER and redis-cache...${NC}"
  docker rm -f "$NGINX_PROXY_CONTAINER" redis-cache 2>/dev/null || true
}

# 🧹 Remove all containers and volumes related to each site
remove_site_containers() {
  for site in $(get_site_list); do
    echo -e "${YELLOW}🧨 Removing containers for site: $site${NC}"
    docker rm -f "$site-php" "$site-mariadb" 2>/dev/null || true
    docker volume rm "${site}_db_data" 2>/dev/null || true
  done
}