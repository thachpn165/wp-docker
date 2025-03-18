calculate_mariadb_config() {
    local total_ram=$(get_total_ram)
    local total_cpu=$(get_total_cpu)

    # Cấu hình tối ưu dựa theo tài nguyên hệ thống
    max_connections=$((total_ram / 4))  # Số kết nối tối đa (1/4 RAM)
    query_cache_size=32  # Dung lượng cache query (MB)
    innodb_buffer_pool_size=$((total_ram / 2))  # InnoDB Buffer Pool = 1/2 RAM
    innodb_log_file_size=$((innodb_buffer_pool_size / 4))  # InnoDB Log File = 1/4 Buffer Pool
    table_open_cache=$((total_ram * 8))  # Cache bảng mở
    thread_cache_size=$((total_cpu * 8))  # Cache luồng

    # Giới hạn giá trị tối thiểu và tối đa hợp lý
    max_connections=$((max_connections > 100 ? max_connections : 100))
    innodb_buffer_pool_size=$((innodb_buffer_pool_size > 256 ? innodb_buffer_pool_size : 256))
    innodb_log_file_size=$((innodb_log_file_size > 64 ? innodb_log_file_size : 64))
    table_open_cache=$((table_open_cache > 400 ? table_open_cache : 400))
    thread_cache_size=$((thread_cache_size > 16 ? thread_cache_size : 16))

    # Trả về giá trị tính toán
    echo "$max_connections,$query_cache_size,$innodb_buffer_pool_size,$innodb_log_file_size,$table_open_cache,$thread_cache_size"
}

apply_mariadb_config() {
    local mariadb_conf_path="$1"

    # Nếu file đã tồn tại, xoá để tạo mới
    if [ -f "$mariadb_conf_path" ]; then
        rm -f "$mariadb_conf_path"
    fi

    # Lấy thông số tối ưu
    IFS=',' read -r max_connections query_cache_size innodb_buffer_pool_size innodb_log_file_size table_open_cache thread_cache_size <<< "$(calculate_mariadb_config)"

    # Đặt cứng giá trị `innodb_io_capacity = 1500`
    innodb_io_capacity=1500

    # Tạo file cấu hình
    cat > "$mariadb_conf_path" <<EOF
[mysqld]
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
max_connections = $max_connections
query_cache_size = ${query_cache_size}M
innodb_buffer_pool_size = ${innodb_buffer_pool_size}M
innodb_log_file_size = ${innodb_log_file_size}M
innodb_flush_log_at_trx_commit = 1
innodb_lock_wait_timeout = 50
table_open_cache = $table_open_cache
thread_cache_size = $thread_cache_size
innodb_io_capacity = $innodb_io_capacity
EOF

    echo "✅ Đã tạo cấu hình MariaDB tối ưu tại $mariadb_conf_path"
}