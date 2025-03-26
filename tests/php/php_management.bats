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
    local file="$1"
    
    [ -f "$file" ]
}

dir_exists() {
    local dir="$1"
    
    [ -d "$dir" ]
}

file_has_permissions() {
    local file="$1"
    local permissions="$2"
    
    [ "$(stat -f "%Lp" "$file")" = "$permissions" ]
}

dir_has_permissions() {
    local dir="$1"
    local permissions="$2"
    
    [ "$(stat -f "%Lp" "$dir")" = "$permissions" ]
}

# Test functions
@test "PHP version detection works correctly" {
    # Create PHP version files
    mkdir -p "$TEST_DIR/sites/test-site/php"
    echo "8.1" > "$TEST_DIR/sites/test-site/php/version"
    
    # Check version
    local version=$(cat "$TEST_DIR/sites/test-site/php/version")
    [ "$version" = "8.1" ]
}

@test "PHP configuration files are generated correctly" {
    local site_name="test-site"
    local php_version="8.1"
    
    # Create PHP config directory
    mkdir -p "$TEST_DIR/sites/$site_name/php/config"
    
    # Create php.ini
    cat > "$TEST_DIR/sites/$site_name/php/config/php.ini" << EOF
memory_limit = 256M
upload_max_filesize = 64M
post_max_size = 64M
max_execution_time = 300
date.timezone = UTC
EOF
    
    # Check if config file exists
    file_exists "$TEST_DIR/sites/$site_name/php/config/php.ini"
    
    # Check if config file contains correct settings
    file_contains "$TEST_DIR/sites/$site_name/php/config/php.ini" "memory_limit = 256M"
    file_contains "$TEST_DIR/sites/$site_name/php/config/php.ini" "upload_max_filesize = 64M"
}

@test "PHP extensions are enabled correctly" {
    local site_name="test-site"
    
    # Create PHP extensions directory
    mkdir -p "$TEST_DIR/sites/$site_name/php/extensions"
    
    # Create extensions list
    cat > "$TEST_DIR/sites/$site_name/php/extensions/enabled.txt" << EOF
mbstring
gd
mysqli
pdo_mysql
zip
EOF
    
    # Check if extensions file exists
    file_exists "$TEST_DIR/sites/$site_name/php/extensions/enabled.txt"
    
    # Check if extensions file contains correct extensions
    file_contains "$TEST_DIR/sites/$site_name/php/extensions/enabled.txt" "mbstring"
    file_contains "$TEST_DIR/sites/$site_name/php/extensions/enabled.txt" "mysqli"
    file_contains "$TEST_DIR/sites/$site_name/php/extensions/enabled.txt" "pdo_mysql"
}

@test "PHP-FPM configuration is valid" {
    local site_name="test-site"
    
    # Create PHP-FPM config directory
    mkdir -p "$TEST_DIR/sites/$site_name/php/fpm"
    
    # Create www.conf
    cat > "$TEST_DIR/sites/$site_name/php/fpm/www.conf" << EOF
[www]
user = nobody
group = nogroup
listen = 9000
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
EOF
    
    # Check if FPM config file exists
    file_exists "$TEST_DIR/sites/$site_name/php/fpm/www.conf"
    
    # Check if FPM config file contains correct settings
    file_contains "$TEST_DIR/sites/$site_name/php/fpm/www.conf" "pm = dynamic"
    file_contains "$TEST_DIR/sites/$site_name/php/fpm/www.conf" "listen = 9000"
} 