#!/bin/bash

# ==========================================================
# 🌐 Network & Internet Utilities (Refactored for v1.1.7-beta)
# ==========================================================

# ✅ Kiểm tra port đang được sử dụng hay không
is_port_in_use() {
  local port="$1"
  netstat -tuln | grep -q ":$port "
}

# ✅ Kiểm tra kết nối Internet
is_internet_connected() {
  ping -c 1 8.8.8.8 &> /dev/null
}

# ✅ Kiểm tra domain có phân giải được không
is_domain_resolvable() {
  local domain="$1"
  if command -v timeout &>/dev/null; then
    timeout 3 nslookup "$domain" &> /dev/null
  else
    nslookup "$domain" | grep -q "Name:"
  fi
}

# ✅ Kiểm tra Docker network tồn tại không
is_network_exists() {
  local network_name="$1"
  if docker network ls --format '{{.Name}}' | grep -q "^${network_name}$"; then
    debug_log "$(printf "$DEBUG_DOCKER_NETWORK_EXISTS" "$network_name")"
    return 0
  else
    debug_log "$(printf "$DEBUG_DOCKER_NETWORK_NOT_EXISTS" "$network_name")"
    return 1
  fi
}

# ✅ Tạo Docker network nếu chưa có
create_docker_network() {
  local network_name="$1"
  if ! is_network_exists "$network_name"; then
    print_msg info "$(printf "$INFO_CREATE_DOCKER_NETWORK" "$network_name")"
    docker network create "$network_name"
    print_msg success "$(printf "$SUCCESS_DOCKER_NETWORK_CREATED" "$network_name")"
  else
    print_msg success "$(printf "$SUCCESS_DOCKER_NETWORK_EXISTS" "$network_name")"
  fi
}