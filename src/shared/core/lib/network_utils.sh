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

# =====================================
# network_check_http: Check if a URL is reachable via HTTP/HTTPS
# Parameters: $1 - URL to check
# Behavior: Returns the URL if reachable, prints error otherwise
# Usage: validated_url=network_check_http "http://example.com"
network_check_http() {
  local url="$1"

  _is_missing_param "$url" "--url" || return 1

  if ! [[ "$url" =~ ^https?://[a-zA-Z0-9.-]+ ]]; then
    print_msg error "❌ Invalid URL format: $url"
    return 1
  fi

  # Auto-upgrade to HTTPS if needed
  if [[ "$url" =~ ^http:// ]]; then
    print_msg warning "⚠️ URL uses HTTP. Switching to HTTPS for secure check."
    url="${url/http:/https:}"
  fi

  if ! command -v curl &>/dev/null; then
    print_msg error "❌ curl is not installed. Cannot check HTTP status."
    return 1
  fi

  local status
  status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 -L "$url")
  if [[ "$status" != "200" ]]; then
    print_msg error "❌ URL returned HTTP status $status for: $url"
    return 1
  fi

  # ✅ Echo URL back for use by caller
  echo "$url"
  return 0
}
