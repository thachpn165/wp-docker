#!/bin/bash

# Kiểm tra xem một container có đang chạy không
is_container_running() {
    local container_name="$1"
    
    # Mock khi ở TEST_MODE
    if [[ "$TEST_MODE" == true && "$TEST_ALWAYS_READY" == true ]]; then
        return 0  # container luôn sẵn sàng trong TEST_MODE
    fi

    # Kiểm tra container khi không ở TEST_MODE
    docker ps --format '{{.Names}}' | grep -q "^${container_name}$"
}

# Kiểm tra xem một volume Docker có tồn tại không
is_volume_exist() {
    local volume_name="$1"
    
    # Mock khi ở TEST_MODE
    if [[ "$TEST_MODE" == true && "$TEST_ALWAYS_READY" == true ]]; then
        return 0  # volume luôn tồn tại trong TEST_MODE
    fi

    # Kiểm tra volume khi không ở TEST_MODE
    docker volume ls --format '{{.Name}}' | grep -q "^${volume_name}$"
}

# Xóa container nếu nó đang chạy
remove_container() {
    local container_name="$1"
    
    # Mock khi ở TEST_MODE
    if [[ "$TEST_MODE" == true && "$TEST_ALWAYS_READY" == true ]]; then
        echo "🧪 Bỏ qua xóa container trong TEST_MODE: $container_name"
        return 0  # không làm gì trong TEST_MODE
    fi

    # Thực hiện xóa container khi không ở TEST_MODE
    if is_container_running "$container_name"; then
        echo "🛑 Đang dừng và xóa container: $container_name..."
        docker rm -f "$container_name"
    fi
}


# Xóa volume nếu nó tồn tại
remove_volume() {
    local volume_name="$1"
    if is_volume_exist "$volume_name"; then
        echo "🗑️ Đang xóa volume: $volume_name..."
        docker volume rm "$volume_name"
    fi
}

# ✅ Hàm tự động cài Docker
install_docker() {
    echo -e "${YELLOW}🔧 Cài đặt Docker...${NC}"
    if [ -x "$(command -v apt-get)" ]; then
        sudo apt-get update
        sudo apt-get install -y ca-certificates curl gnupg lsb-release
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg | \
            sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
          https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") \
          $(lsb_release -cs) stable" | \
          sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    elif [ -x "$(command -v yum)" ]; then
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    else
        echo -e "${RED}❌ Không hỗ trợ hệ điều hành này để cài Docker tự động.${NC}"
        exit 1
    fi
}

# ✅ Hàm cài Docker Compose từ GitHub release
install_docker_compose() {
    echo -e "${YELLOW}📦 Đang cài đặt Docker Compose plugin...${NC}"

    DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
    mkdir -p "$DOCKER_CONFIG/cli-plugins"

    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)

    # Chuẩn hóa kiến trúc
    case "$ARCH" in
        x86_64) ARCH="x86_64" ;;
        aarch64 | arm64) ARCH="aarch64" ;;
        *) echo "❌ Không hỗ trợ kiến trúc máy: $ARCH" && return 1 ;;
    esac

    COMPOSE_URL="https://github.com/docker/compose/releases/download/v2.34.0/docker-compose-${OS}-${ARCH}"
    DEST="$DOCKER_CONFIG/cli-plugins/docker-compose"

    echo "➡️  Tải từ: $COMPOSE_URL"
    curl -SL "$COMPOSE_URL" -o "$DEST"
    chmod +x "$DEST"

    if docker compose version &>/dev/null; then
        echo -e "${GREEN}✅ Docker Compose đã được cài đặt thành công.${NC}"
    else
        echo -e "${RED}❌ Cài đặt Docker Compose thất bại. Hãy kiểm tra thủ công.${NC}"
    fi
}


# ✅ Hàm kiểm tra Docker đã chạy chưa
start_docker_if_needed() {
    if (! docker stats --no-stream &> /dev/null); then
        echo -e "${YELLOW}🌀 Docker chưa chạy. Đang khởi động Docker...${NC}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            open --background -a Docker
            while ! docker system info > /dev/null 2>&1; do
                echo -n "."
                sleep 1
            done
            echo " ✅"
        else
            sudo systemctl start docker
        fi
    else
        echo -e "${GREEN}✅ Docker đang hoạt động.${NC}"
    fi
}

# ✅ Hàm kiểm tra & thêm user vào group docker nếu cần
check_docker_group() {
    # Kiểm tra hệ điều hành
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS không yêu cầu người dùng thuộc nhóm docker
        echo -e "${GREEN}✅ Trên macOS, không cần thêm user vào nhóm docker.${NC}"
    else
        # Linux - kiểm tra và thêm user vào nhóm docker nếu cần
        if ! groups "$USER" | grep -q docker; then
            echo -e "${YELLOW}➕ Thêm user '$USER' vào nhóm docker...${NC}"
            sudo usermod -aG docker "$USER"
            echo -e "${GREEN}✅ Đã thêm user vào nhóm docker. Hãy logout/login lại để có hiệu lực.${NC}"
        fi
    fi
}

# 🧩 Hàm docker exec nhanh
docker_exec_php() {
    docker exec -u "$PHP_USER" -i "$PHP_CONTAINER" sh -c "$1"
}


# Nếu script này được gọi trực tiếp, thực thi hàm tương ứng
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        is_docker_running) is_docker_running ;;
        check_docker_status) check_docker_status ;;
        *) echo -e "${RED}❌ Lệnh không hợp lệ!${NC} Sử dụng: $0 {is_docker_running|check_docker_status}" ;;
    esac
fi


# 🧹 Xoá container chính bao gồm nginx proxy và redis-cache
remove_core_containers() {
  echo -e "${YELLOW}🧹 Đang xoá các container $NGINX_PROXY_CONTAINER và redis-cache...${NC}"
  docker rm -f "$NGINX_PROXY_CONTAINER" redis-cache 2>/dev/null || true
}

# 🧹 Xoá toàn bộ container và volume liên quan tới từng site
remove_site_containers() {
  for site in $(get_site_list); do
    echo -e "${YELLOW}🧨 Đang xoá container cho site: $site${NC}"
    docker rm -f "$site-php" "$site-mariadb" 2>/dev/null || true
    docker volume rm "${site}_db_data" 2>/dev/null || true
  done
}