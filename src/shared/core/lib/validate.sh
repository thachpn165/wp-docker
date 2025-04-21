# =============================================
# 🌐 _is_valid_domain – Validate a domain name format
# ---------------------------------------------
# Usage:
#   if ! _is_valid_domain "$domain"; then ...
# =============================================
_is_valid_domain() {
    local domain="$1"

    if [[ ${#domain} -gt 253 ]]; then
        print_msg error "❌ Domain exceeds maximum length (253 characters): $domain"
        return 1
    fi

    if ! [[ "$domain" =~ ^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$ ]]; then
        print_msg error "❌ Invalid domain format: $domain"
        return 1
    fi

    IFS='.' read -ra labels <<<"$domain"
    for label in "${labels[@]}"; do
        if [[ ${#label} -gt 63 ]]; then
            print_msg error "❌ Domain label exceeds maximum length (63 characters): $label"
            return 1
        fi
    done

    return 0
}
# =============================================
# 🛡️ _is_missing_param – Check if required param is missing (with escape protection)
# ---------------------------------------------
# Usage:
#   _is_missing_param "$domain" "--domain" || return 1
# =============================================
_is_missing_param() {
    local value="$1"
    local label="$2"

    # Escape label to avoid injection in error output
    local escaped_label
    escaped_label="$(printf "%q" "$label")"

    if [[ -z "$value" || "$value" == "$label" ]]; then
        print_and_debug error "$(printf "$ERROR_MISSING_PARAM: %s" "$escaped_label")"
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

    # Kiểm tra độ dài tối đa
    if [[ ${#email} -gt 320 ]]; then
        print_msg error "❌ Email exceeds maximum length (320 characters): $email"
        return 1
    fi

    # Kiểm tra định dạng email
    if ! [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
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
    # Check if Docker daemon is running (cross-platform)
    if ! docker info >/dev/null 2>&1; then
        print_msg error "❌ Docker is not running or not accessible."
        return 1
    fi

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
    local escaped_file_path
    escaped_file_path=$(printf "%q" "$file_path")
    if [[ -f "$file_path" ]]; then
        if [[ ! -r "$file_path" ]]; then
            print_msg error "❌ File exists but is not readable: $escaped_file_path"
            return 1
        fi
        if [[ ! -w "$file_path" ]]; then
            print_msg warning "⚠️ File exists but is not writable: $escaped_file_path"
        fi
        return 0
    fi

    return 1
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
            mkdir -p "$dir" || {
                debug_log error "❌ Failed to create directory: $dir"
                return 1
            }
        else
            return 1
        fi
    fi
}

# =============================================
# 🧪 _is_missing_var – Check if a variable is unset or empty
# ---------------------------------------------
# Usage:
#   _is_missing_var "$VAR" "VAR_NAME" || return 1
#
# Parameters:
#   $1 - Giá trị của biến (giá trị cần kiểm tra)
#   $2 - Tên biến hiển thị để báo lỗi (ví dụ: "DOMAIN")
# =============================================
_is_missing_var() {
    local value="$1"
    local name="$2"

    if [[ -z "$value" ]]; then
        print_and_debug error "❌ Missing or empty variable: \$$name"
        return 1
    fi
    return 0
}
