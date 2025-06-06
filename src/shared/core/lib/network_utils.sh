#!/bin/bash

# ==========================================================
# 🌐 Network & Internet Utilities (Refactored for v1.1.7-beta)
# This script provides utility functions for managing Docker networks
# and checking the reachability of URLs via HTTP/HTTPS.
#
# Functions:
# - core_create_docker_network: Create a Docker network if it does not already exist.
#   Parameters: $1 - network name
#
# - network_check_http: Check if a URL is reachable via HTTP/HTTPS.
#   Parameters: $1 - URL to check
# ==========================================================

core_create_docker_network() {
  local network_name="$1"
  if ! _is_docker_network_exists "$network_name"; then
    print_msg info "$(printf "$INFO_CORE_CREATE_DOCKER_NETWORK" "$network_name")"
    docker network create "$network_name"
    print_msg success "$(printf "$SUCCESS_DOCKER_NETWORK_CREATED" "$network_name")"
  else
    print_msg success "$(printf "$SUCCESS_DOCKER_NETWORK_EXISTS" "$network_name")"
  fi
}

network_check_http() {
  local url="$1"

  _is_missing_param "$url" "--url" || return 1

  if ! [[ "$url" =~ ^https?://[a-zA-Z0-9.-]+ ]]; then
    print_msg error "❌ Invalid URL format: $url"
    return 1
  fi

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

  echo "$url" >/dev/null 2>&1
  return 0
}
