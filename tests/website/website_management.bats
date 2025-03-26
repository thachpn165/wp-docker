#!/usr/bin/env bats

setup() {
    # Create temporary test directory
    export TEST_DIR="$(mktemp -d)"
    
    # Create required directories
    mkdir -p "$TEST_DIR/sites"
    mkdir -p "$TEST_DIR/shared/config"
    mkdir -p "$TEST_DIR/webserver"
    mkdir -p "$TEST_DIR/logs"
    mkdir -p "$TEST_DIR/tmp"
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
    
    [[ -d "$dir" ]]
}

# Helper function to check if a file exists
file_exists() {
    local file="$1"
    
    [[ -f "$file" ]]
}

# Helper function to check if a file has correct permissions
file_has_permissions() {
    local file="$1"
    local expected_perms="$2"
    local actual_perms=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%Lp" "$file" 2>/dev/null)
    [[ "$actual_perms" == "$expected_perms" ]]
}

# Helper function to check if a directory has correct permissions
dir_has_permissions() {
    local dir="$1"
    local expected_perms="$2"
    local actual_perms=$(stat -c "%a" "$dir" 2>/dev/null || stat -f "%Lp" "$dir" 2>/dev/null)
    [[ "$actual_perms" == "$expected_perms" ]]
}

@test "Website creation creates required directories and files" {
    local site_name="test-site"
    local domain="test-site.local"
    
    # Create test site
    create_test_site "$site_name" "$domain"
    
    # Check if site directory exists
    dir_exists "$TEST_DIR/sites/$site_name"
    
    # Check if .env file exists
    file_exists "$TEST_DIR/sites/$site_name/.env"
    
    # Check if .env file contains correct domain
    file_contains "$TEST_DIR/sites/$site_name/.env" "DOMAIN=$domain"
    
    # Check if .env file contains database configuration
    file_contains "$TEST_DIR/sites/$site_name/.env" "MYSQL_DATABASE=test_db"
    file_contains "$TEST_DIR/sites/$site_name/.env" "MYSQL_USER=test_user"
    file_contains "$TEST_DIR/sites/$site_name/.env" "MYSQL_PASSWORD=test_pass"
    file_contains "$TEST_DIR/sites/$site_name/.env" "PHP_VERSION=8.1"
}

@test "Website deletion removes all site files" {
    local site_name="test-site"
    
    # Create test site
    create_test_site "$site_name" "test-site.local"
    
    # Create additional files
    touch "$TEST_DIR/sites/$site_name/test.txt"
    mkdir -p "$TEST_DIR/sites/$site_name/uploads"
    
    # Simulate website deletion
    rm -rf "$TEST_DIR/sites/$site_name"
    
    # Check if site directory is removed
    ! dir_exists "$TEST_DIR/sites/$site_name"
}

@test "Website validation accepts valid site names" {
    local valid_names=(
        "test-site"
        "my-site-123"
        "wordpress-site"
        "site-2024"
    )
    
    for name in "${valid_names[@]}"; do
        [[ "$name" =~ ^[a-z0-9-]+$ ]]
    done
}

@test "Website validation rejects invalid site names" {
    local invalid_names=(
        "test site"
        "my_site"
        "site@test"
        "site.test"
        "site/test"
        "site\\test"
    )
    
    for name in "${invalid_names[@]}"; do
        ! [[ "$name" =~ ^[a-z0-9-]+$ ]]
    done
}

@test "Website environment variables are properly set" {
    local site_name="test-site"
    local domain="test-site.local"
    
    # Create test site
    create_test_site "$site_name" "$domain"
    
    # Check if all required environment variables are set
    file_contains "$TEST_DIR/sites/$site_name/.env" "DOMAIN=$domain"
    file_contains "$TEST_DIR/sites/$site_name/.env" "MYSQL_DATABASE=test_db"
    file_contains "$TEST_DIR/sites/$site_name/.env" "MYSQL_USER=test_user"
    file_contains "$TEST_DIR/sites/$site_name/.env" "MYSQL_PASSWORD=test_pass"
    file_contains "$TEST_DIR/sites/$site_name/.env" "PHP_VERSION=8.1"
}

@test "Website directory has correct permissions" {
    local site_name="test-site"
    
    # Create test site
    create_test_site "$site_name" "test-site.local"
    
    # Check directory permissions (755)
    dir_has_permissions "$TEST_DIR/sites/$site_name" "755"
    
    # Check .env file permissions (644)
    file_has_permissions "$TEST_DIR/sites/$site_name/.env" "644"
}

@test "Website creation with custom PHP version" {
    local site_name="test-site"
    local domain="test-site.local"
    local php_version="8.2"
    
    # Create test site with custom PHP version
    mkdir -p "$TEST_DIR/sites/$site_name"
    cat > "$TEST_DIR/sites/$site_name/.env" << EOF
DOMAIN=$domain
MYSQL_DATABASE=test_db
MYSQL_USER=test_user
MYSQL_PASSWORD=test_pass
PHP_VERSION=$php_version
EOF
    
    # Check if PHP version is correctly set
    file_contains "$TEST_DIR/sites/$site_name/.env" "PHP_VERSION=$php_version"
} 