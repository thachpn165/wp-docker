#!/bin/bash

# Kiểm tra xem một container có đang chạy không
is_container_running() {
    local container_name="$1"
    docker ps --format '{{.Names}}' | grep -q "^${container_name}$"
}

# Kiểm tra xem một network Docker có tồn tại không
is_network_exist() {
    local network_name="$1"
    docker network ls --format '{{.Name}}' | grep -q "^${network_name}$"
}

# Kiểm tra xem một volume Docker có tồn tại không
is_volume_exist() {
    local volume_name="$1"
    docker volume ls --format '{{.Name}}' | grep -q "^${volume_name}$"
}

# Xóa container nếu nó đang chạy
remove_container() {
    local container_name="$1"
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

# 🐳 **Hàm kiểm tra Docker có đang chạy không**
is_docker_running() {
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}⚠️ Docker chưa chạy! Vui lòng khởi động Docker trước khi sử dụng.${NC}"
        return 1
    else
        return 0
    fi
}

# 🛠️ **Hàm kiểm tra trạng thái Docker và hiển thị thông tin**
check_docker_status() {
    echo -e "${YELLOW}🔍 Kiểm tra trạng thái Docker...${NC}"
    
    if is_docker_running; then
        echo -e "${GREEN}✅ Docker đang hoạt động bình thường.${NC}"
        #echo -e "${YELLOW}📊 Thống kê tổng quan Docker:${NC}"
        #docker system df
    else
        echo -e "${RED}❌ Docker không hoạt động. Hãy kiểm tra lại!${NC}"
    fi
}

# Nếu script này được gọi trực tiếp, thực thi hàm tương ứng
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        is_docker_running) is_docker_running ;;
        check_docker_status) check_docker_status ;;
        *) echo -e "${RED}❌ Lệnh không hợp lệ!${NC} Sử dụng: $0 {is_docker_running|check_docker_status}" ;;
    esac
fi