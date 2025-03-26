#!/usr/bin/env bats

# Load common test helper functions
setup() {
    # Create temporary test directory
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
    
    # Create mock directories structure
    mkdir -p "$TEST_DIR/sites"
    mkdir -p "$TEST_DIR/shared/config"
    mkdir -p "$TEST_DIR/webserver"
    mkdir -p "$TEST_DIR/logs"
    mkdir -p "$TEST_DIR/tmp"
    
    # Colors for output
    export RED='\033[0;31m'
    export GREEN='\033[0;32m'
    export YELLOW='\033[1;33m'
    export BLUE='\033[0;34m'
    export NC='\033[0m'
    
    # Create mock config file
    cat > "$TEST_DIR/shared/config/config.sh" << 'EOF'
# Mock configuration
SITES_DIR="/tmp/sites"
TMP_DIR="/tmp/tmp"
LOGS_DIR="/tmp/logs"
WEBSERVER_TYPE="nginx"
PHP_VERSIONS=("8.1" "8.2" "8.3")
EOF
    
    # Source the config file
    source "$TEST_DIR/shared/config/config.sh"
    
    # Override paths to use TEST_DIR
    export SITES_DIR="$TEST_DIR/sites"
    export TMP_DIR="$TEST_DIR/tmp"
    export LOGS_DIR="$TEST_DIR/logs"
}

teardown() {
    # Clean up test directory
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

# Helper function to create a test site
create_test_site() {
    local site_name="$1"
    local domain="$2"
    
    mkdir -p "$TEST_DIR/sites/$site_name"
    cat > "$TEST_DIR/sites/$site_name/.env" << EOF
DOMAIN=$domain
MYSQL_DATABASE=test_db
MYSQL_USER=test_user
MYSQL_PASSWORD=test_pass
PHP_VERSION=8.1
EOF
}

# Helper function to check if a file contains specific content
file_contains() {
    local file="$1"
    local content="$2"
    
    grep -q "$content" "$file"
}

# Helper function to check if a directory exists
dir_exists() {
    local dir="$1"
    
    [ -d "$dir" ]
}

# Helper function to check if a file exists
file_exists() {
    local file="$1"
    
    [ -f "$file" ]
}

# Helper function to check if a command exists
command_exists() {
    local cmd="$1"
    
    command -v "$cmd" >/dev/null 2>&1
}

# Helper function to check if a process is running
process_running() {
    local process="$1"
    
    pgrep -f "$process" >/dev/null
}

# Helper function to check if a port is in use
port_in_use() {
    local port="$1"
    
    lsof -i ":$port" >/dev/null 2>&1
}

# Helper function to check if a container is running
container_running() {
    local container="$1"
    
    docker ps --filter "name=$container" --format "{{.Names}}" | grep -q "^$container$"
}

# Helper function to check if a container exists
container_exists() {
    local container="$1"
    
    docker ps -a --filter "name=$container" --format "{{.Names}}" | grep -q "^$container$"
}

# Helper function to check if a network exists
network_exists() {
    local network="$1"
    
    docker network ls --filter "name=$network" --format "{{.Name}}" | grep -q "^$network$"
}

# Helper function to check if a volume exists
volume_exists() {
    local volume="$1"
    
    docker volume ls --filter "name=$volume" --format "{{.Name}}" | grep -q "^$volume$"
}

# Helper function to check if a file has correct permissions
file_has_permissions() {
    local file="$1"
    local permissions="$2"
    
    [ "$(stat -f "%Lp" "$file")" = "$permissions" ]
}

# Helper function to check if a directory has correct permissions
dir_has_permissions() {
    local dir="$1"
    local permissions="$2"
    
    [ "$(stat -f "%Lp" "$dir")" = "$permissions" ]
}

# Helper function to check if a file is owned by user
file_owned_by() {
    local file="$1"
    local user="$2"
    
    [ "$(stat -f "%Su" "$file")" = "$user" ]
}

# Helper function to check if a directory is owned by user
dir_owned_by() {
    local dir="$1"
    local user="$2"
    
    [ "$(stat -f "%Su" "$dir")" = "$user" ]
}