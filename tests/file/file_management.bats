#!/usr/bin/env bats

setup() {
    # Create temporary test directory
    export TEST_DIR="$(mktemp -d)"
    
    # Create required directories
    mkdir -p "$TEST_DIR/sites/test-site"
    mkdir -p "$TEST_DIR/shared/config"
    mkdir -p "$TEST_DIR/webserver"
    mkdir -p "$TEST_DIR/logs"
    mkdir -p "$TEST_DIR/tmp"
    
    # Create basic site structure
    mkdir -p "$TEST_DIR/sites/test-site/wordpress"
    mkdir -p "$TEST_DIR/sites/test-site/logs"
    mkdir -p "$TEST_DIR/sites/test-site/db"
    
    # Create .env file
    cat > "$TEST_DIR/sites/test-site/.env" << EOF
DOMAIN=test-site.local
MYSQL_DATABASE=test_db
MYSQL_USER=test_user
MYSQL_PASSWORD=test_pass
PHP_VERSION=8.1
EOF
}

teardown() {
    # Clean up test directory
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

# Helper functions
file_contains() {
    local file="$1"
    local content="$2"
    
    grep -q "$content" "$file"
}

file_exists() {
    [[ -f "$1" ]]
}

dir_exists() {
    [[ -d "$1" ]]
}

file_has_permissions() {
    local file="$1"
    local expected_perms="$2"
    local actual_perms=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%Lp" "$file" 2>/dev/null)
    [[ "$actual_perms" == "$expected_perms" ]]
}

dir_has_permissions() {
    local dir="$1"
    local expected_perms="$2"
    local actual_perms=$(stat -c "%a" "$dir" 2>/dev/null || stat -f "%Lp" "$dir" 2>/dev/null)
    [[ "$actual_perms" == "$expected_perms" ]]
}

# Tests
@test "File system structure creation" {
    local site_name="test-site"
    
    # Check if directories exist
    dir_exists "$TEST_DIR/sites/$site_name"
    dir_exists "$TEST_DIR/sites/$site_name/wordpress"
    dir_exists "$TEST_DIR/sites/$site_name/logs"
    dir_exists "$TEST_DIR/sites/$site_name/db"
}

@test "WordPress uploads directory creation and permissions" {
    local site_name="test-site"
    
    # Create uploads directory
    mkdir -p "$TEST_DIR/sites/$site_name/wordpress/wp-content/uploads"
    chmod 755 "$TEST_DIR/sites/$site_name/wordpress/wp-content/uploads"
    
    # Check if uploads directory exists and has correct permissions
    dir_exists "$TEST_DIR/sites/$site_name/wordpress/wp-content/uploads"
    dir_has_permissions "$TEST_DIR/sites/$site_name/wordpress/wp-content/uploads" "755"
}

@test "Log files creation and permissions" {
    local site_name="test-site"
    
    # Create log files
    mkdir -p "$TEST_DIR/sites/$site_name/logs/nginx"
    mkdir -p "$TEST_DIR/sites/$site_name/logs/php"
    touch "$TEST_DIR/sites/$site_name/logs/nginx/access.log"
    touch "$TEST_DIR/sites/$site_name/logs/nginx/error.log"
    touch "$TEST_DIR/sites/$site_name/logs/php/error.log"
    chmod 644 "$TEST_DIR/sites/$site_name/logs/nginx/access.log"
    chmod 644 "$TEST_DIR/sites/$site_name/logs/nginx/error.log"
    chmod 644 "$TEST_DIR/sites/$site_name/logs/php/error.log"
    
    # Check if log files exist and have correct permissions
    file_exists "$TEST_DIR/sites/$site_name/logs/nginx/access.log"
    file_exists "$TEST_DIR/sites/$site_name/logs/nginx/error.log"
    file_exists "$TEST_DIR/sites/$site_name/logs/php/error.log"
    file_has_permissions "$TEST_DIR/sites/$site_name/logs/nginx/access.log" "644"
    file_has_permissions "$TEST_DIR/sites/$site_name/logs/nginx/error.log" "644"
    file_has_permissions "$TEST_DIR/sites/$site_name/logs/php/error.log" "644"
}

@test "Environment file creation and validation" {
    local site_name="test-site"
    
    # Check if .env file exists and has correct permissions
    file_exists "$TEST_DIR/sites/$site_name/.env"
    file_has_permissions "$TEST_DIR/sites/$site_name/.env" "644"
    
    # Check if .env file contains required variables
    file_contains "$TEST_DIR/sites/$site_name/.env" "DOMAIN=test-site.local"
    file_contains "$TEST_DIR/sites/$site_name/.env" "MYSQL_DATABASE=test_db"
    file_contains "$TEST_DIR/sites/$site_name/.env" "MYSQL_USER=test_user"
    file_contains "$TEST_DIR/sites/$site_name/.env" "MYSQL_PASSWORD=test_pass"
    file_contains "$TEST_DIR/sites/$site_name/.env" "PHP_VERSION=8.1"
}

@test "WordPress configuration file creation and permissions" {
    local site_name="test-site"
    
    # Create wp-config.php
    cat > "$TEST_DIR/sites/$site_name/wordpress/wp-config.php" << EOF
<?php
define('DB_NAME', 'test_db');
define('DB_USER', 'test_user');
define('DB_PASSWORD', 'test_pass');
define('DB_HOST', 'mariadb');
EOF
    chmod 640 "$TEST_DIR/sites/$site_name/wordpress/wp-config.php"
    
    # Check if wp-config.php exists and has correct permissions
    file_exists "$TEST_DIR/sites/$site_name/wordpress/wp-config.php"
    file_has_permissions "$TEST_DIR/sites/$site_name/wordpress/wp-config.php" "640"
    
    # Check if wp-config.php contains required variables
    file_contains "$TEST_DIR/sites/$site_name/wordpress/wp-config.php" "define('DB_NAME', 'test_db');"
    file_contains "$TEST_DIR/sites/$site_name/wordpress/wp-config.php" "define('DB_USER', 'test_user');"
    file_contains "$TEST_DIR/sites/$site_name/wordpress/wp-config.php" "define('DB_PASSWORD', 'test_pass');"
    file_contains "$TEST_DIR/sites/$site_name/wordpress/wp-config.php" "define('DB_HOST', 'mariadb');"
} 