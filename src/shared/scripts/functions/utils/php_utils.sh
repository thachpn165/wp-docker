#!/bin/bash
# =====================================
# calculate_php_fpm_values: Calculate optimal PHP-FPM process values for WordPress
# Parameters:
#   $1 - total RAM in MB
#   $2 - total CPU cores
# Returns:
#   pm pm.max_children pm.start_servers pm.min_spare_servers pm.max_spare_servers
# =====================================
calculate_php_fpm_values() {
  local total_ram=$1 # MB
  local total_cpu=$2 # Number of cores

  # Define server resource groups
  local is_low_resource=false
  local is_medium_resource=false
  local is_high_resource=false

  # Server categorization
  if [[ $total_cpu -lt 2 || $total_ram -lt 2048 ]]; then
    is_low_resource=true
  elif [[ $total_cpu -ge 8 && $total_ram -ge 8192 ]]; then
    is_high_resource=true
  else
    is_medium_resource=true
  fi

  # WordPress-specific tuning
  local reserved_ram=0
  local avg_process_size=0
  local pm_mode=""

  # Set reserved RAM and process size based on server group
  if [[ $is_low_resource == true ]]; then
    reserved_ram=384
    avg_process_size=40
    pm_mode="ondemand"
  elif [[ $is_medium_resource == true ]]; then
    reserved_ram=512
    avg_process_size=50
    pm_mode="ondemand"
  elif [[ $is_high_resource == true ]]; then # Thay đổi ở đây
    reserved_ram=1024
    avg_process_size=60
    pm_mode="dynamic"
  fi

  # Calculate available RAM
  local available_ram=$((total_ram - reserved_ram))

  # Calculate max_children based on RAM
  local ram_based_max=$((available_ram / avg_process_size))

  # Calculate max_children based on CPU
  local cpu_multiplier=0
  if [[ $is_low_resource == true ]]; then
    cpu_multiplier=3
  elif [[ $is_medium_resource == true ]]; then
    cpu_multiplier=5
  else
    cpu_multiplier=8
  fi

  local cpu_based_max=$((total_cpu * cpu_multiplier))

  # Take the smaller value to avoid resource exhaustion
  local max_children=$((ram_based_max < cpu_based_max ? ram_based_max : cpu_based_max))
  max_children=$((max_children > 4 ? max_children : 4))

  # Calculate other values based on server group
  local start_servers=0
  local min_spare_servers=0
  local max_spare_servers=0

  if [[ $pm_mode == "dynamic" ]]; then
    start_servers=$((total_cpu + 2))
    start_servers=$((start_servers < max_children ? start_servers : max_children))
    min_spare_servers=$total_cpu
    min_spare_servers=$((min_spare_servers < start_servers ? min_spare_servers : start_servers))
    max_spare_servers=$((total_cpu * 3))
    max_spare_servers=$((max_spare_servers < max_children ? max_spare_servers : max_children))
  else # ondemand
    start_servers=0
    min_spare_servers=0
    max_spare_servers=$((total_cpu * 2))
    max_spare_servers=$((max_spare_servers < max_children ? max_spare_servers : max_children))
  fi

  # Ensure minimum values
  min_spare_servers=$((min_spare_servers > 1 ? min_spare_servers : 1))
  max_spare_servers=$((max_spare_servers > 2 ? max_spare_servers : 2))

  # Return all calculated values
  echo "$pm_mode $max_children $start_servers $min_spare_servers $max_spare_servers"
}

# =====================================
# create_optimized_php_fpm_config: Generate PHP-FPM config file with optimized values for WordPress
# Parameters:
#   $1 - php_fpm_conf_path: path to output config file
# Behavior:
#   - Removes directory if exists
#   - Creates file and writes optimized config based on system RAM/CPU
# =====================================
create_optimized_php_fpm_config() {
  local domain="$1"
  local php_fpm_conf_path="$SITES_DIR/$domain/php/php-fpm.conf"

  if [[ -d "$php_fpm_conf_path" ]]; then
    print_msg warning "$(printf "$WARNING_PHP_FPM_REMOVE_FILE" "$php_fpm_conf_path")"
    remove_file "$php_fpm_conf_path"
  fi

  if [[ ! -f "$php_fpm_conf_path" ]]; then
    touch "$php_fpm_conf_path"
  fi

  local total_ram total_cpu
  total_ram=$(get_total_ram)
  total_cpu=$(get_total_cpu)

  read pm_mode max_children start_servers min_spare_servers max_spare_servers <<<"$(calculate_php_fpm_values "$total_ram" "$total_cpu")"

  # Create optimized config with WordPress-specific settings
  cat >"$php_fpm_conf_path" <<EOF
[www]
user = nobody
group = nogroup
listen = 9000
pm = $pm_mode
pm.max_children = $max_children
pm.start_servers = $start_servers
pm.min_spare_servers = $min_spare_servers
pm.max_spare_servers = $max_spare_servers
pm.process_idle_timeout = 10s
pm.max_requests = 1000
slowlog=/var/www/logs/php_slow.log
request_slowlog_timeout = 10
request_terminate_timeout = 60
EOF

  print_msg success "$(printf "$SUCCESS_PHP_FPM_CONFIG_CREATED" "$php_fpm_conf_path")"
  print_msg info "$(printf "Server resources: %s CPU cores, %s MB RAM" "$total_cpu" "$total_ram")"
  print_msg info "$(printf "PHP-FPM mode: %s" "$pm_mode")"
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
