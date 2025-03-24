# 📌 Lấy tổng dung lượng RAM (MB), hoạt động trên cả Linux & macOS
get_total_ram() {
    if command -v free >/dev/null 2>&1; then
        free -m | awk '/^Mem:/{print $2}'
    else
        sysctl -n hw.memsize | awk '{print $1 / 1024 / 1024}'
    fi
}

# 📌 Lấy tổng số CPU core, hoạt động trên cả Linux & macOS
get_total_cpu() {
    if command -v nproc >/dev/null 2>&1; then
        nproc
    else
        sysctl -n hw.ncpu
    fi
}

# 🧩 Hàm xử lý sed tương thích macOS/Linux
sedi() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# Kiểm tra và thiết lập múi giờ của Việt Nam trên máy chủ
setup_timezone() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        current_tz=$(timedatectl | grep "Time zone" | awk '{print $3}')
        if [[ "$current_tz" != "Asia/Ho_Chi_Minh" ]]; then
            echo -e "${YELLOW}🌏 Đặt múi giờ hệ thống về Asia/Ho_Chi_Minh...${NC}"
            sudo timedatectl set-timezone Asia/Ho_Chi_Minh
            echo -e "${GREEN}✅ Đã đổi múi giờ hệ thống.${NC}"
        fi
    fi
}