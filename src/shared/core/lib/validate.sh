# =============================================
# 🌐 _is_valid_domain – Validate a domain name format
# ---------------------------------------------
# Usage:
#   if ! _is_valid_domain "$domain"; then ...
# =============================================
_is_valid_domain() {
    local domain="$1"

    _is_missing_param "$domain" "domain" || return 1

    # Must match standard domain pattern: sub.domain.tld
    if ! [[ "$domain" =~ ^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$ ]]; then
        print_msg error "$(printf "$ERROR_DOMAIN_INVALID_FORMAT" "$domain")"
        return 1
    fi

    # Optional: disallow domain starting or ending with hyphen
    if [[ "$domain" =~ (^[-])|([-]$) ]]; then
        print_msg error "$(printf "$ERROR_DOMAIN_INVALID_HYPHEN" "$domain")"
        return 1
    fi

    return 0
}

# =============================================
# ⚠️ _is_missing_param – Check if required param is missing
# ---------------------------------------------
# Usage:
#   _is_missing_param "$var" "--domain" || return 1
# =============================================
_is_missing_param() {
    local value="$1"
    local label="$2"

    if [[ -z "$value" || "$value" == "$label" ]]; then
        print_and_debug error "$ERROR_MISSING_PARAM: $label"
        return 1
    fi
}

# =============================================
# 📧 _is_valid_email – Validate email address format
# ---------------------------------------------
# Usage:
#   _is_valid_email "$email" || return 1
# =============================================
_is_valid_email() {
    local email="$1"

    _is_missing_param "$email" "email" || return 1

    # RFC 5322-compliant basic pattern, accepts name@domain.com or name@domain.com.vn
    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        print_msg error "❌ Invalid email format: $email"
        return 1
    fi

    return 0
}

# ===========================
# 🔍 Check if multiple containers are running
# Returns true if all specified containers are running.
# Parameters:
#   $@ - List of container names to check
# Global variables used: None
# Result: Returns true if all containers are running, false otherwise
# ===========================
_is_container_running() {
    local all_running=true

    for container_name in "$@"; do
        if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
            debug_log "[Docker] ✅ Container '$container_name' is running"
        else
            debug_log "[Docker] ❌ Container '$container_name' is NOT running"
            all_running=false
        fi
    done

    [[ "$all_running" == true ]]
}
# =====================================
# _is_docker_network_exists: Check if a Docker network exists
# Parameters: $1 - network name
# Returns: 0 if exists, 1 otherwise
# =====================================
_is_docker_network_exists() {
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
# _is_test_mode: Check if running in TEST_MODE
# Returns: 0 if true
# =====================================
_is_test_mode() {
    [[ "$TEST_MODE" == true ]]
}

# =====================================
# _is_file_exist: Check if a file exists
# Parameters:
#   $1 - file_path
# Returns:
#   0 if exists, 1 if not
# =====================================
_is_file_exist() {
    local file_path="$1"
    [[ -f "$file_path" ]]
}

# =====================================
# _is_directory_exist: Check if a directory exists
# Parameters:
#   $1 - dir: Directory path
#   $2 - create_if_missing (optional): If not "false", directory will be created
# Returns:
#   0 if directory exists or is created, 1 otherwise
# =====================================
_is_directory_exist() {
    local dir="$1"
    local create_if_missing="$2"

    if [[ ! -d "$dir" ]]; then
        if [[ "$create_if_missing" == "true" ]]; then
            debug_log "[_is_directory_exist] Directory not exist, creating: $dir"
            print_msg debug "$MSG_NOT_FOUND : $dir"
            mkdir -p "$dir"
        else
            return 1
        fi
    fi
}
