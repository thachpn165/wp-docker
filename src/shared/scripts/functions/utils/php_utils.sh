#!/bin/bash

# 📌 Tính toán giá trị tối ưu dựa trên RAM & CPU
calculate_php_fpm_values() {
  local total_ram=$1     # MB
  local total_cpu=$2     # Số core

  local ram_based_max=$((total_ram / 30))
  local cpu_based_max=$((total_cpu * 4))

  local max_children=$((ram_based_max < cpu_based_max ? ram_based_max : cpu_based_max))
  max_children=$((max_children > 4 ? max_children : 4))

  local start_servers=$((max_children / 2))
  local min_spare_servers=$((start_servers / 2))
  local max_spare_servers=$((start_servers * 2))

  start_servers=$((start_servers > 2 ? start_servers : 2))
  min_spare_servers=$((min_spare_servers > 1 ? min_spare_servers : 1))
  max_spare_servers=$((max_spare_servers > 4 ? max_spare_servers : 4))

  debug_log "$(printf "$DEBUG_PHP_FPM_CALCULATED" "$total_ram" "$total_cpu" "$max_children" "$start_servers" "$min_spare_servers" "$max_spare_servers")"
  echo "$max_children $start_servers $min_spare_servers $max_spare_servers"
}

# 📂 Tạo cấu hình PHP-FPM tối ưu
create_optimized_php_fpm_config() {
  local php_fpm_conf_path="$1"

  if [[ -d "$php_fpm_conf_path" ]]; then
    print_msg warning "$(printf "$WARNING_PHP_FPM_REMOVE_DIR" "$php_fpm_conf_path")"
    rm -rf "$php_fpm_conf_path"
  fi

  if [[ ! -f "$php_fpm_conf_path" ]]; then
    touch "$php_fpm_conf_path"
  fi

  local total_ram total_cpu
  total_ram=$(get_total_ram)
  total_cpu=$(get_total_cpu)

  read max_children start_servers min_spare_servers max_spare_servers <<< "$(calculate_php_fpm_values "$total_ram" "$total_cpu")"

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

  print_msg success "$(printf "$SUCCESS_PHP_FPM_CONFIG_CREATED" "$php_fpm_conf_path")"
}

# Function to get PHP Container in .env
php_get_container() {
  local env_file="$1"
  local container_name

  if [[ -f "$env_file" ]]; then
    container_name=$(env_get_value "$env_file" "CONTAINER_PHP")
    echo "$container_name"
  else
    print_and_debug error "$ERROR_BACKUP_ENV_FILE_NOT_FOUND : $env_file"
    return 1
  fi
}