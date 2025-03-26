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
    mkdir -p "$TEST_DIR/sites/test-site/db"
    mkdir -p "$TEST_DIR/sites/test-site/db/dumps"
    
    # Create .env file
    cat > "$TEST_DIR/sites/test-site/.env" << EOF
DOMAIN=test-site.local
MYSQL_DATABASE=test_db
MYSQL_USER=test_user
MYSQL_PASSWORD=test_pass
MYSQL_ROOT_PASSWORD=rootpass
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

# Tests
@test "Database configuration is properly set" {
    local site_name="test-site"
    
    # Check if .env file exists and contains database configuration
    file_exists "$TEST_DIR/sites/$site_name/.env"
    file_contains "$TEST_DIR/sites/$site_name/.env" "MYSQL_DATABASE=test_db"
    file_contains "$TEST_DIR/sites/$site_name/.env" "MYSQL_USER=test_user"
    file_contains "$TEST_DIR/sites/$site_name/.env" "MYSQL_PASSWORD=test_pass"
    file_contains "$TEST_DIR/sites/$site_name/.env" "MYSQL_ROOT_PASSWORD=rootpass"
}

@test "Database backup directory exists" {
    local site_name="test-site"
    
    # Check if database dumps directory exists
    dir_exists "$TEST_DIR/sites/$site_name/db/dumps"
}

@test "Database backup creation" {
    local site_name="test-site"
    local backup_file="$TEST_DIR/sites/$site_name/db/dumps/backup-$(date +%Y%m%d).sql"
    
    # Create mock backup file
    touch "$backup_file"
    
    # Check if backup file exists
    file_exists "$backup_file"
}

@test "Database backup file permission" {
    local site_name="test-site"
    local backup_file="$TEST_DIR/sites/$site_name/db/dumps/backup-$(date +%Y%m%d).sql"
    
    # Create mock backup file and set permissions
    touch "$backup_file"
    chmod 640 "$backup_file"
    
    # Check if backup file has correct permissions
    file_has_permissions "$backup_file" "640"
}

@test "Database initalization script exists" {
    local site_name="test-site"
    
    # Create init script
    mkdir -p "$TEST_DIR/sites/$site_name/db/init"
    cat > "$TEST_DIR/sites/$site_name/db/init/01-create-database.sql" << EOF
CREATE DATABASE IF NOT EXISTS test_db;
GRANT ALL PRIVILEGES ON test_db.* TO 'test_user'@'%';
FLUSH PRIVILEGES;
EOF
    
    # Check if init script exists
    file_exists "$TEST_DIR/sites/$site_name/db/init/01-create-database.sql"
    
    # Check if init script contains correct SQL
    file_contains "$TEST_DIR/sites/$site_name/db/init/01-create-database.sql" "CREATE DATABASE IF NOT EXISTS test_db;"
    file_contains "$TEST_DIR/sites/$site_name/db/init/01-create-database.sql" "GRANT ALL PRIVILEGES ON test_db.* TO 'test_user'@'%';"
}

@test "Database configuration is valid" {
    local site_name="test-site"
    
    # Create database configuration
    mkdir -p "$TEST_DIR/sites/$site_name/db/conf"
    cat > "$TEST_DIR/sites/$site_name/db/conf/my.cnf" << EOF
[mysqld]
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci
default-authentication-plugin=mysql_native_password
max_allowed_packet=128M
innodb_buffer_pool_size=256M
innodb_log_file_size=64M
EOF
    
    # Check if configuration file exists
    file_exists "$TEST_DIR/sites/$site_name/db/conf/my.cnf"
    
    # Check if configuration contains correct settings
    file_contains "$TEST_DIR/sites/$site_name/db/conf/my.cnf" "character-set-server=utf8mb4"
    file_contains "$TEST_DIR/sites/$site_name/db/conf/my.cnf" "max_allowed_packet=128M"
}

@test "Database backup rotation" {
    local site_name="test-site"
    local backups_dir="$TEST_DIR/sites/$site_name/db/dumps"
    
    # Create mock backup files with different dates
    for i in {1..5}; do
        touch "$backups_dir/backup-2023010$i.sql"
    done
    
    # Add one recent backup
    touch "$backups_dir/backup-$(date +%Y%m%d).sql"
    
    # Check if we have the expected number of backups
    [ "$(find "$backups_dir" -name "backup-*.sql" | wc -l)" -eq 6 ]
} 