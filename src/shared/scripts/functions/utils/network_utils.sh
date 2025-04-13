#!/bin/bash

# ==========================================================
# 🌐 Network & Internet Utilities (Refactored for v1.1.7-beta)
# ==========================================================

# =====================================
# is_port_in_use: Check if a given port is currently in use
# Parameters: $1 - port number
# Returns: 0 if in use, 1 otherwise
# =====================================
is_port_in_use() {
  local port="$1"
  netstat -tuln | grep -q ":$port "
}

# =====================================
# is_internet_connected: Check if the machine has internet connectivity
# Returns: 0 if connected, 1 otherwise
# =====================================
is_internet_connected() {
  ping -c 1 8.8.8.8 &> /dev/null
}

# =====================================
# is_domain_resolvable: Check if a domain can be resolved via DNS
# Parameters: $1 - domain name
# Returns: 0 if resolvable, 1 otherwise
# =====================================
is_domain_resolvable() {
  local domain="$1"
  if command -v timeout &>/dev/null; then
    timeout 3 nslookup "$domain" &> /dev/null
  else
    nslookup "$domain" | grep -q "Name:"
  fi
}

# =====================================
# is_network_exists: Check if a Docker network exists
# Parameters: $1 - network name
# Returns: 0 if exists, 1 otherwise
# =====================================
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

# =====================================
# create_docker_network: Create a Docker network if it does not already exist
# Parameters: $1 - network name
# Behavior: Prints success or info messages accordingly
# =====================================
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