# 🖥️ **Get System Information (Linux & macOS)**
get_system_info() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        CPU_MODEL=$(sysctl -n machdep.cpu.brand_string)
        TOTAL_CPU=$(sysctl -n hw.ncpu)
        TOTAL_RAM=$(sysctl -n hw.memsize | awk '{print $1 / 1024 / 1024}')
        USED_RAM=$(vm_stat | awk -F ': +' '/Pages active/ {print $2 * 4096 / 1024 / 1024}')
        DISK_USAGE=$(df -h / | awk 'NR==2 {print $3 " / " $2}')

        # Get IP Address on macOS
        IP_ADDRESS=$(ipconfig getifaddr en0)
        if [ -z "$IP_ADDRESS" ]; then
            IP_ADDRESS=$(ifconfig | awk '/inet / && $2 !~ /127\.0\.0\.1/ {print $2; exit}')
        fi
    else
        # Linux
        CPU_MODEL=$(lscpu | grep "Model name" | awk -F ':' '{print $2}' | xargs)
        TOTAL_CPU=$(nproc)
        TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
        USED_RAM=$(free -m | awk '/^Mem:/{print $3}')
        DISK_USAGE=$(df -h / | awk 'NR==2 {print $3 " / " $2}')

        # Get IP Address on Linux
        IP_ADDRESS=$(hostname -I | awk '{print $1}')
    fi
}

# 🐳 **Check Docker Status**
check_docker_status() {
    if docker info &>/dev/null; then
        echo -e "$CHECKMARK Docker"
    else
        echo -e "$CROSSMARK Docker"
    fi
}

# 🌐 **Check Docker Network Status**
check_docker_network() {
    if docker network inspect "$DOCKER_NETWORK" &>/dev/null; then
        echo -e "$CHECKMARK Docker Network ($DOCKER_NETWORK)"
    else
        echo -e "$CROSSMARK Docker Network ($DOCKER_NETWORK)"
    fi
}

# 🚀 **Check NGINX Proxy Status**
check_nginx_status() {
    if is_container_running "$NGINX_PROXY_CONTAINER"; then
        echo -e "$CHECKMARK NGINX Proxy"
    else
        echo -e "$CROSSMARK NGINX Proxy"
    fi
}