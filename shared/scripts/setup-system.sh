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

# ✅ Kiểm tra Docker đã cài đặt chưa
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker chưa được cài đặt trên hệ thống.${NC}"

    OS_TYPE=$(uname -s)
    case "$OS_TYPE" in
        Linux*)
            install_docker
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
