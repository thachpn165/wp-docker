# 📌 Tính toán giá trị tối ưu dựa trên RAM và CPU
calculate_php_fpm_values() {
    local total_ram=$1     # tính theo MB
    local total_cpu=$2     # số core CPU

    # 👉 Ước lượng số process theo RAM: mỗi PHP process ~30MB
    local ram_based_max=$((total_ram / 30))

    # 👉 Giới hạn theo CPU: gợi ý an toàn là CPU x 4
    local cpu_based_max=$((total_cpu * 4))

    # 👉 Chọn giá trị thấp hơn giữa RAM và CPU
    local max_children=$((ram_based_max < cpu_based_max ? ram_based_max : cpu_based_max))

    # 👉 Thiết lập mặc định tối thiểu
    max_children=$((max_children > 4 ? max_children : 4))
    local start_servers=$((max_children / 2))
    local min_spare_servers=$((start_servers / 2))
    local max_spare_servers=$((start_servers * 2))

    # Tránh giá trị quá thấp
    start_servers=$((start_servers > 2 ? start_servers : 2))
    min_spare_servers=$((min_spare_servers > 1 ? min_spare_servers : 1))
    max_spare_servers=$((max_spare_servers > 4 ? max_spare_servers : 4))

    echo "$max_children $start_servers $min_spare_servers $max_spare_servers"
}


create_optimized_php_fpm_config() {
    local php_fpm_conf_path="$1"

    # Nếu đã tồn tại dưới dạng thư mục, hãy xóa đi
    if [ -d "$php_fpm_conf_path" ]; then
        echo "⚠️ Xóa thư mục '$php_fpm_conf_path' vì cần tạo tập tin..."
        rm -rf "$php_fpm_conf_path"
    fi

    # Tạo tập tin mới nếu chưa tồn tại
    if [ ! -f "$php_fpm_conf_path" ]; then
        touch "$php_fpm_conf_path"
    fi

    # Lấy thông tin hệ thống
    local total_ram=$(get_total_ram)
    local total_cpu=$(get_total_cpu)

    # Tính toán thông số tối ưu
    read max_children start_servers min_spare_servers max_spare_servers <<< $(calculate_php_fpm_values "$total_ram" "$total_cpu")

    # Ghi cấu hình tối ưu vào file
    cat > "$php_fpm_conf_path" <<EOF
[www]
user = www-data
group = www-data
listen = 9000
pm = dynamic
pm.max_children = $max_children
pm.start_servers = $start_servers
pm.min_spare_servers = $min_spare_servers
pm.max_spare_servers = $max_spare_servers
pm.process_idle_timeout = 10s
pm.max_requests = 500
EOF

    echo "✅ Đã tạo cấu hình PHP-FPM tối ưu tại $php_fpm_conf_path"
}
