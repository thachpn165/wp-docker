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