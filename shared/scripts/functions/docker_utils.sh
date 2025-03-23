#!/bin/bash

# Kiểm tra xem một container có đang chạy không
is_container_running() {
    local container_name="$1"
    docker ps --format '{{.Names}}' | grep -q "^${container_name}$"
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
    if ! docker info &> /dev/null; then
        echo -e "${YELLOW}⚠️ Docker chưa chạy. Đang cố gắng khởi động Docker...${NC}"

        OS_TYPE=$(uname -s)
        if [[ "$OS_TYPE" == "Linux" ]]; then
            if [ -f /etc/os-release ]; then
                OS_ID=$(grep ^ID= /etc/os-release | cut -d= -f2 | tr -d '"')
                OS_ID_LIKE=$(grep ^ID_LIKE= /etc/os-release | cut -d= -f2 | tr -d '"')

                if [[ "$OS_ID" =~ (ubuntu|debian) || "$OS_ID_LIKE" =~ (debian) ]]; then
                    sudo systemctl start docker || sudo service docker start

                elif [[ "$OS_ID" =~ (centos|rhel|alma) || "$OS_ID_LIKE" =~ (rhel|fedora) ]]; then
                    sudo service docker start

                else
                    echo -e "${RED}⚠️ Không xác định được bản phân phối Linux. Vui lòng khởi động Docker thủ công.${NC}"
                    return 1
                fi
            else
                echo -e "${RED}⚠️ Không tìm thấy /etc/os-release. Không thể xác định hệ điều hành.${NC}"
                return 1
            fi

        elif [[ "$OS_TYPE" == "Darwin" ]]; then
            echo -e "${YELLOW}🖥️ Vui lòng mở Docker Desktop để khởi động Docker trên macOS.${NC}"
            return 1

        else
            echo -e "${RED}⚠️ Không xác định được hệ điều hành. Vui lòng khởi động Docker thủ công.${NC}"
            return 1
        fi

        # Kiểm tra lại sau khi đã cố khởi động
        sleep 3
        if ! docker info &> /dev/null; then
            echo -e "${RED}❌ Docker vẫn chưa chạy sau khi thử khởi động.${NC}"
            return 1
        else
            echo -e "${GREEN}✅ Docker đã được khởi động thành công.${NC}"
            return 0
        fi

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