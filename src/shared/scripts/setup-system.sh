#!/bin/bash

# ========================================
# ⚙️ setup-system.sh – Khởi tạo hệ thống WP Docker
# ========================================

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
source "$FUNCTIONS_DIR/php/php_get_version.sh"

# ✅ Thiết lập múi giờ hệ thống (nếu cần)
clear
setup_timezone

# ✅ Kiểm tra Docker
if ! command -v docker &> /dev/null; then
    install_docker
else
    echo -e "${GREEN}✅ Docker đã được cài đặt.${NC}"
fi

# ✅ Kiểm tra Docker Compose plugin
if ! docker compose version &> /dev/null; then
    install_docker_compose
else
    echo -e "${GREEN}✅ Docker Compose đã được cài đặt.${NC}"
fi

# ✅ Khởi động Docker nếu chưa chạy
start_docker_if_needed

# ✅ Kiểm tra nhóm docker
check_docker_group

# ✅ Khởi động nginx-proxy và redis nếu chưa chạy
echo -e "${YELLOW}🚀 Kiểm tra và khởi động nginx-proxy và redis-cache nếu cần...${NC}"
cd "$NGINX_PROXY_DIR"

if ! docker compose ps | grep -q "nginx-proxy.*Up"; then
    echo -e "${YELLOW}🌀 Container nginx-proxy chưa chạy. Đang khởi động...${NC}"
    docker compose up -d
fi

# ⏳ Chờ container nginx-proxy thực sự khởi động
echo -e "${YELLOW}⏳ Đang kiểm tra trạng thái container nginx-proxy...${NC}"
for i in {1..10}; do
    status=$(docker inspect -f '{{.State.Status}}' nginx-proxy 2>/dev/null)
    if [[ "$status" == "running" ]]; then
        echo -e "${GREEN}✅ Container nginx-proxy đã chạy.${NC}"
        break
    fi
    sleep 1
done

if [[ "$status" != "running" ]]; then
    echo -e "${RED}❌ Container nginx-proxy KHÔNG thể khởi động.${NC}"
    echo -e "${YELLOW}📋 Dưới đây là log khởi động gần nhất của container:${NC}\n"
    docker logs nginx-proxy 2>&1 | tail -n 30
    echo -e "\n${RED}💥 Vui lòng kiểm tra lại file cấu hình, volume mount hoặc cổng đang sử dụng.${NC}"
    exit 1
fi


cd "$BASE_DIR"

# ✅ Kiểm tra và tạo Docker network nếu chưa có
echo -e "${YELLOW}🌐 Kiểm tra mạng Docker '${DOCKER_NETWORK}'...${NC}"
create_docker_network "$DOCKER_NETWORK"

# ✅ Lấy danh sách tag PHP mới nhất từ Docker Hub
php_get_version

# ✅ Hiển thị thông tin cấu hình
echo -e "${CYAN}📁 BASE_DIR: $BASE_DIR${NC}"
echo -e "${CYAN}📝 DEV_MODE: $DEV_MODE${NC}"
echo -e "${CYAN}📦 LOGS_DIR: $LOGS_DIR${NC}"

echo -e "\n${GREEN}✅ Hệ thống đã sẵn sàng để sử dụng WP Docker LEMP.${NC}"
