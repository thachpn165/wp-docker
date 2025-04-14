#!/bin/bash

# =====================================
# calculate_php_fpm_values: Calculate optimal PHP-FPM process values based on system resources
# Parameters:
#   $1 - total RAM in MB
#   $2 - total CPU cores
# Returns:
#   max_children start_servers min_spare_servers max_spare_servers
# =====================================
calculate_php_fpm_values() {
  local total_ram=$1     # MB
  local total_cpu=$2     # Number of cores

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

  echo "$max_children $start_servers $min_spare_servers $max_spare_servers"
}

# =====================================
# create_optimized_php_fpm_config: Generate PHP-FPM config file with optimized values
# Parameters:
#   $1 - php_fpm_conf_path: path to output config file
# Behavior:
#   - Removes directory if exists
#   - Creates file and writes optimized config based on system RAM/CPU
# =====================================
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

# =====================================
# php_get_container: Get the PHP container name for a domain from JSON config
# Parameters:
#   $1 - domain
# Returns:
#   container name if found, 1 if not found or error
# =====================================
php_get_container() {
  local domain="$1"

  if [[ -z "$domain" ]]; then
    print_and_debug error "$ERROR_MISSING_PARAM :php_get_container(domain)"
    return 1
  fi

  local container_name
  container_name=$(json_get_site_value "$domain" "CONTAINER_PHP")

  if [[ -n "$container_name" ]]; then
    echo "$container_name"
  else
    #print_and_debug error "$ERROR_DOCKER_PHP_CONTAINER_NOT_FOUND: $domain"
    return 1
  fi
}