# ==================================================
# File: validate.sh
# Description: This script contains utility functions for validation tasks,
#              such as validating domain names, email addresses, Docker containers,
#              files, directories, and flags.
# Functions:
#   - _is_valid_domain: Validate a domain name format.
#       Parameters:
#           $1 - domain: The domain name to validate.
#       Returns: 0 if valid, 1 otherwise.
#   - _is_missing_param: Check if a required parameter is missing.
#       Parameters:
#           $1 - value: The parameter value to check.
#           $2 - label: The parameter label for error messages.
#       Returns: 0 if valid, 1 otherwise.
#   - _is_valid_email: Validate an email address format.
#       Parameters:
#           $1 - email: The email address to validate.
#       Returns: 0 if valid, 1 otherwise.
#   - _is_container_running: Check if multiple Docker containers are running.
#       Parameters:
#           $@ - List of container names to check.
#       Returns: 0 if all containers are running, 1 otherwise.
#   - _is_docker_network_exists: Check if a Docker network exists.
#       Parameters:
#           $1 - network_name: The name of the Docker network.
#       Returns: 0 if exists, 1 otherwise.
#   - _is_test_mode: Check if the script is running in test mode.
#       Parameters: None.
#       Returns: 0 if true, 1 otherwise.
#   - _is_file_exist: Check if a file exists and has the correct permissions.
#       Parameters:
#           $1 - file_path: The path to the file.
#       Returns: 0 if the file exists, 1 otherwise.
#   - _is_directory_exist: Check if a directory exists, optionally creating it.
#       Parameters:
#           $1 - dir: The directory path.
#           $2 - create_if_missing: If "true", create the directory if missing.
#       Returns: 0 if the directory exists or is created, 1 otherwise.
#   - _is_missing_var: Check if a variable is unset or empty.
#       Parameters:
#           $1 - value: The value of the variable to check.
#           $2 - name: The variable name for error messages.
#       Returns: 0 if valid, 1 otherwise.
#   - _has_flag: Check if a specific flag is present in the arguments.
#       Parameters:
#           $1 - flag: The flag to check (e.g., "--force").
#           $@ - Full argument list.
#       Returns: 0 if the flag is present, 1 otherwise.
# ==================================================

_is_valid_domain() {
    local domain="$1"
    domain="$(echo "$domain" | xargs)" # Trim whitespace
    _is_missing_var "$domain" "domain" || return 1

    if [[ ${#domain} -gt 253 ]]; then
        print_msg error "$ERROR_DOMAIN_EXCEEDS_MAX_LENGTH: $domain"
        return 1
    fi

    if ! [[ "$domain" =~ ^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$ ]]; then
        print_msg error "$ERROR_DOMAIN_INVALID_FORMAT: $domain"
        return 1
    fi

    if [[ "$domain" =~ (^[-])|([-]$) ]]; then
        print_msg error "$ERROR_DOMAIN_INVALID_HYPHEN: $domain"
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

_is_missing_param() {
    local value="$1"
    local label="$2"

    local escaped_label
    escaped_label="$(printf "%q" "$label")"

    if [[ -z "$value" || "$value" == "$label" ]]; then
        print_and_debug error "$(printf "$ERROR_MISSING_PARAM: %s" "$escaped_label")"
        return 1
    fi
}

_is_valid_email() {
    local email="$1"

    _is_missing_param "$email" "email" || return 1

    if [[ ${#email} -gt 320 ]]; then
        print_msg error "$ERROR_EMAIL_EXCEEDS_MAX_LENGTH"
        return 1
    fi

    if ! [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        print_msg error "$ERROR_EMAIL_INVALID_FORMAT: $email"
        return 1
    fi

    return 0
}

_is_container_running() {
    if ! docker info >/dev/null 2>&1; then
        print_msg error "$ERROR_DOCKER_NOT_RUNNING"
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

_is_test_mode() {
    [[ "$TEST_MODE" == true ]]
}

_is_file_exist() {
    local file_path="$1"

    if [[ ! -f "$file_path" ]]; then
        print_msg error "$MSG_NOT_FOUND: $file_path"
        return 1
    fi

    if [[ ! -r "$file_path" ]]; then
        print_msg error "$ERROR_FILE_NOT_READABLE: $(printf "%q" "$file_path")"
        return 1
    fi

    if [[ ! -w "$file_path" ]]; then
        print_msg warning "$ERROR_FILE_NOT_WRITABLE: $(printf "%q" "$file_path")"
    fi

    return 0
}

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

_is_missing_var() {
    local value="$1"
    local name="$2"

    if [[ -z "$value" ]]; then
        print_and_debug error "❌ Missing or empty variable: \$$name"
        return 1
    fi
    return 0
}

_has_flag() {
    local flag="$1"
    shift

    for arg in "$@"; do
        if [[ "$arg" == "$flag" ]]; then
            return 0
        fi
    done
    return 1
}

_is_arm() {
    local arch
    arch="$(uname -m)"

    debug_log "[CHECK] Architecture detected: $arch"

    case "$arch" in
    aarch64 | armv7l | arm64)
        return 0
        ;;
    *)
        return 1
        ;;
    esac
}
