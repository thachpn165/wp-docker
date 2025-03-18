# 📌 Tính toán giá trị tối ưu dựa trên RAM và CPU
calculate_php_fpm_values() {
    local total_ram=$1
    local total_cpu=$2

    # Tính toán tối ưu dựa trên tổng RAM
    local max_children=$((total_ram / 20))
    local start_servers=$((max_children / 2))
    local min_spare_servers=$((start_servers / 2))
    local max_spare_servers=$((start_servers * 2))

    # Giới hạn giá trị hợp lý
    max_children=$((max_children > 10 ? max_children : 10))
    start_servers=$((start_servers > 5 ? start_servers : 5))
    min_spare_servers=$((min_spare_servers > 2 ? min_spare_servers : 2))
    max_spare_servers=$((max_spare_servers > 10 ? max_spare_servers : 10))

    # Xuất kết quả
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
