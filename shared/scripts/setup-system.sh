#!/bin/bash

# Import config.sh
CONFIG_FILE="shared/config/config.sh"
while [ ! -f "$CONFIG_FILE" ]; do
    CONFIG_FILE="../$CONFIG_FILE"
    if [ "$(pwd)" = "/" ]; then
        echo "❌ Lỗi: Không tìm thấy config.sh!" >&2
        exit 1
    fi
done
source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/wp_utils.sh"

# ✅ Hàm tự động cài đặt Docker mới nhất
install_docker() {
    OS_ID=$(grep ^ID= /etc/os-release | cut -d= -f2 | tr -d '"')
    OS_ID_LIKE=$(grep ^ID_LIKE= /etc/os-release | cut -d= -f2 | tr -d '"')

    echo -e "${YELLOW}🔄 Đang tiến hành cài đặt Docker...${NC}"

    if [[ "$OS_ID" =~ (ubuntu|debian) || "$OS_ID_LIKE" =~ (debian) ]]; then
        sudo apt-get update
        sudo apt-get install -y \
            ca-certificates \
            curl \
            gnupg \
            lsb-release

        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/${OS_ID}/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

        echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${OS_ID} \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    elif [[ "$OS_ID" =~ (centos|rhel|alma) || "$OS_ID_LIKE" =~ (rhel|fedora) ]]; then
        sudo dnf -y install dnf-plugins-core
        sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo systemctl enable --now docker

    else
        echo -e "${RED}⚠️ Không hỗ trợ tự động cài Docker trên hệ điều hành này.${NC}"
        return 1
    fi

    echo -e "${GREEN}✅ Docker đã được cài đặt thành công.${NC}"
    return 0
}

# Kiểm tra và cài đặt Docker-compose
install_docker_compose() {
    if docker compose version &> /dev/null; then
        echo -e "${GREEN}✅ Docker Compose đã được cài đặt sẵn.${NC}"
        return 0
    fi

    echo -e "${YELLOW}🔄 Đang cài đặt Docker Compose Plugin (V2)...${NC}"

    COMPOSE_VERSION="2.24.5"
    OS_TYPE=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH_TYPE=$(uname -m)

    case "$ARCH_TYPE" in
        x86_64) ARCH_TYPE="x86_64" ;;
        aarch64 | arm64) ARCH_TYPE="aarch64" ;;
        *) echo -e "${RED}❌ Không hỗ trợ kiến trúc CPU: $ARCH_TYPE${NC}"; return 1 ;;
    esac

    DEST_DIR="/usr/local/lib/docker/cli-plugins"
    sudo mkdir -p "$DEST_DIR"
    sudo curl -SL "https://github.com/docker/compose/releases/download/v${COMPOSE_VERSION}/docker-compose-${OS_TYPE}-${ARCH_TYPE}" \
        -o "$DEST_DIR/docker-compose"
    sudo chmod +x "$DEST_DIR/docker-compose"

    # Kiểm tra lại
    if docker compose version &> /dev/null; then
        echo -e "${GREEN}✅ Cài đặt Docker Compose Plugin thành công.${NC}"
    else
        echo -e "${RED}❌ Cài đặt Docker Compose Plugin thất bại.${NC}"
        return 1
    fi

    # Tạo alias `docker-compose` nếu người dùng vẫn sử dụng dạng cũ
    if ! command -v docker compose &> /dev/null; then
        sudo ln -sf "$DEST_DIR/docker-compose" /usr/local/bin/docker-compose
        echo -e "${BLUE}ℹ️ Tạo liên kết docker compose → docker compose để tương thích với các script cũ.${NC}"
    fi

    return 0
}

# ✅ Kiểm tra Docker đã cài đặt chưa
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker chưa được cài đặt trên hệ thống.${NC}"

    OS_TYPE=$(uname -s)
    case "$OS_TYPE" in
        Linux*)
            install_docker
            install_docker_compose
            if [ $? -ne 0 ]; then
                echo -e "${RED}❌ Cài đặt Docker thất bại. Vui lòng cài đặt thủ công.${NC}"
                exit 1
            fi
            ;;
        Darwin*)
            echo -e "${YELLOW}🔹 Hệ điều hành macOS được phát hiện.${NC}"
            echo -e "${YELLOW}📦 Vui lòng tải Docker Desktop từ: https://www.docker.com/get-started${NC}"
            exit 1
            ;;
        *)
            echo -e "${RED}⚠️ Không xác định được hệ điều hành. Vui lòng tự cài đặt Docker.${NC}"
            exit 1
            ;;
    esac
fi



# ✅ Kiểm tra Docker đã chạy chưa
is_docker_running
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Docker không chạy. Hãy khởi động Docker trước!${NC}"
    exit 1
fi

# ✅ Tạo mạng Docker nếu chưa có
create_docker_network "$DOCKER_NETWORK"

# ✅ Kiểm tra NGINX Proxy container
NGINX_STATUS=$(docker inspect -f '{{.State.Status}}' "$NGINX_PROXY_CONTAINER" 2>/dev/null)

if [[ "$NGINX_STATUS" == "running" ]]; then
    echo -e "${GREEN}✅ NGINX Reverse Proxy đang chạy.${NC}"
elif [[ "$NGINX_STATUS" == "exited" || "$NGINX_STATUS" == "created" ]]; then
    echo -e "${YELLOW}🔄 Đang khởi động lại NGINX Proxy...${NC}"
    docker start "$NGINX_PROXY_CONTAINER"

    sleep 2
    NGINX_STATUS=$(docker inspect -f '{{.State.Status}}' "$NGINX_PROXY_CONTAINER" 2>/dev/null)
    if [[ "$NGINX_STATUS" == "running" ]]; then
        echo -e "${GREEN}✅ NGINX Proxy đã khởi động lại thành công.${NC}"
    else
        echo -e "${RED}❌ Không thể khởi động lại NGINX Proxy. Vui lòng kiểm tra logs.${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}🚀 Khởi động NGINX Reverse Proxy...${NC}"
    bash "$NGINX_SCRIPTS_DIR/setup-nginx.sh"

    sleep 3
    NGINX_STATUS=$(docker inspect -f '{{.State.Status}}' "$NGINX_PROXY_CONTAINER" 2>/dev/null)
    if [[ "$NGINX_STATUS" != "running" ]]; then
        echo -e "${RED}❌ Lỗi: NGINX Proxy không khởi động được. Kiểm tra logs để sửa lỗi.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ NGINX Proxy đã khởi động thành công.${NC}"
fi

# ✅ Kiểm tra và cài đặt WP-CLI nếu chưa có
check_and_update_wp_cli

# ✅ Kiểm tra và thiết lập múi giờ (chỉ áp dụng với Linux)
if [[ "$(uname -s)" == "Linux" ]]; then
    CURRENT_TIMEZONE=$(cat /etc/timezone 2>/dev/null || timedatectl | grep "Time zone" | awk '{print $3}')
    TARGET_TIMEZONE="Asia/Ho_Chi_Minh"

    if [[ "$CURRENT_TIMEZONE" != "$TARGET_TIMEZONE" ]]; then
        echo -e "${YELLOW}🌐 Múi giờ hiện tại là: $CURRENT_TIMEZONE${NC}"
        echo -e "${YELLOW}🛠️ Đang cập nhật múi giờ hệ thống về: $TARGET_TIMEZONE...${NC}"

        if command -v timedatectl &> /dev/null; then
            sudo timedatectl set-timezone "$TARGET_TIMEZONE"
        else
            echo "$TARGET_TIMEZONE" | sudo tee /etc/timezone
            sudo ln -sf /usr/share/zoneinfo/$TARGET_TIMEZONE /etc/localtime
        fi

        echo -e "${GREEN}✅ Múi giờ đã được cập nhật thành công.${NC}"
    else
        echo -e "${GREEN}🕒 Múi giờ hệ thống đã đúng: $CURRENT_TIMEZONE${NC}"
    fi
else
    echo -e "${BLUE}💡 Bỏ qua kiểm tra múi giờ vì không phải hệ điều hành Linux.${NC}"
fi
