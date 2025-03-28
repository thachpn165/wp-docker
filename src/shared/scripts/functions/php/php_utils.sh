# 📌 Calculate optimal values based on RAM and CPU
calculate_php_fpm_values() {
    local total_ram=$1     # in MB
    local total_cpu=$2     # number of CPU cores

    # 👉 Estimate processes based on RAM: each PHP process ~30MB
    local ram_based_max=$((total_ram / 30))

    # 👉 CPU-based limit: safe recommendation is CPU x 4
    local cpu_based_max=$((total_cpu * 4))

    # 👉 Choose lower value between RAM and CPU
    local max_children=$((ram_based_max < cpu_based_max ? ram_based_max : cpu_based_max))

    # 👉 Set minimum default values
    max_children=$((max_children > 4 ? max_children : 4))
    local start_servers=$((max_children / 2))
    local min_spare_servers=$((start_servers / 2))
    local max_spare_servers=$((start_servers * 2))

    # Avoid too low values
    start_servers=$((start_servers > 2 ? start_servers : 2))
    min_spare_servers=$((min_spare_servers > 1 ? min_spare_servers : 1))
    max_spare_servers=$((max_spare_servers > 4 ? max_spare_servers : 4))

    echo "$max_children $start_servers $min_spare_servers $max_spare_servers"
}


create_optimized_php_fpm_config() {
    local php_fpm_conf_path="$1"

    # If exists as directory, remove it
    if [ -d "$php_fpm_conf_path" ]; then
        echo "⚠️ Removing directory '$php_fpm_conf_path' as we need to create a file..."
        rm -rf "$php_fpm_conf_path"
    fi

    # Create new file if it doesn't exist
    if [ ! -f "$php_fpm_conf_path" ]; then
        touch "$php_fpm_conf_path"
    fi

    # Get system information
    local total_ram=$(get_total_ram)
    local total_cpu=$(get_total_cpu)

    # Calculate optimal parameters
    read max_children start_servers min_spare_servers max_spare_servers <<< $(calculate_php_fpm_values "$total_ram" "$total_cpu")

    # Write optimized configuration to file
    cat > "$php_fpm_conf_path" <<EOF
[www]
user = nobody
group = nogroup
listen = 9000
pm = dynamic
pm.max_children = $max_children
pm.start_servers = $start_servers
pm.min_spare_servers = $min_spare_servers
pm.max_spare_servers = $max_spare_servers
pm.process_idle_timeout = 10s
pm.max_requests = 500
EOF

    echo "✅ Created optimized PHP-FPM configuration at $php_fpm_conf_path"
}
