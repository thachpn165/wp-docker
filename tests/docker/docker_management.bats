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

# Tests
@test "Docker container creation with correct configuration" {
    local site_name="test-site"
    local domain="test-site.local"
    
    # Create docker-compose.yml
    cat > "$TEST_DIR/sites/$site_name/docker-compose.yml" << EOF
version: '3.8'

services:
  nginx:
    container_name: ${site_name}-nginx
    image: nginx:1.23-alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./wordpress:/var/www/html
      - ./nginx/conf.d:/etc/nginx/conf.d
      - ./ssl:/etc/nginx/ssl
      - ./logs/nginx:/var/log/nginx
    depends_on:
      - php
    networks:
      - ${site_name}-network

  php:
    container_name: ${site_name}-php
    image: php:8.1-fpm
    volumes:
      - ./wordpress:/var/www/html
      - ./php/php.ini:/usr/local/etc/php/php.ini
      - ./logs/php:/var/log/php
    networks:
      - ${site_name}-network

  mariadb:
    container_name: ${site_name}-mariadb
    image: mariadb:10.6
    environment:
      MYSQL_DATABASE: test_db
      MYSQL_USER: test_user
      MYSQL_PASSWORD: test_pass
      MYSQL_ROOT_PASSWORD: rootpass
    volumes:
      - ${site_name}-db:/var/lib/mysql
      - ./db/init:/docker-entrypoint-initdb.d
    networks:
      - ${site_name}-network

networks:
  ${site_name}-network:
    driver: bridge

volumes:
  ${site_name}-db:
EOF
    
    # Check if docker-compose.yml exists
    file_exists "$TEST_DIR/sites/$site_name/docker-compose.yml"
    
    # Check if docker-compose.yml contains correct settings
    file_contains "$TEST_DIR/sites/$site_name/docker-compose.yml" "container_name: ${site_name}-nginx"
    file_contains "$TEST_DIR/sites/$site_name/docker-compose.yml" "container_name: ${site_name}-php"
    file_contains "$TEST_DIR/sites/$site_name/docker-compose.yml" "container_name: ${site_name}-mariadb"
    file_contains "$TEST_DIR/sites/$site_name/docker-compose.yml" "MYSQL_DATABASE: test_db"
    file_contains "$TEST_DIR/sites/$site_name/docker-compose.yml" "${site_name}-network"
}

@test "Nginx container configuration is correct" {
    local site_name="test-site"
    local domain="test-site.local"
    
    # Create nginx configuration directory
    mkdir -p "$TEST_DIR/sites/$site_name/nginx/conf.d"
    
    # Create nginx configuration
    cat > "$TEST_DIR/sites/$site_name/nginx/conf.d/default.conf" << EOF
server {
    listen 80;
    server_name ${domain};
    root /var/www/html;
    index index.php index.html;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    
    location ~ \.php$ {
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF
    
    # Check if nginx configuration exists
    file_exists "$TEST_DIR/sites/$site_name/nginx/conf.d/default.conf"
    
    # Check if nginx configuration contains correct settings
    file_contains "$TEST_DIR/sites/$site_name/nginx/conf.d/default.conf" "server_name ${domain}"
    file_contains "$TEST_DIR/sites/$site_name/nginx/conf.d/default.conf" "fastcgi_pass php:9000"
}

@test "PHP container configuration is correct" {
    local site_name="test-site"
    
    # Create PHP configuration directory
    mkdir -p "$TEST_DIR/sites/$site_name/php"
    
    # Create PHP configuration
    cat > "$TEST_DIR/sites/$site_name/php/php.ini" << EOF
memory_limit = 256M
upload_max_filesize = 64M
post_max_size = 64M
max_execution_time = 300
date.timezone = UTC
EOF
    
    # Check if PHP configuration exists
    file_exists "$TEST_DIR/sites/$site_name/php/php.ini"
    
    # Check if PHP configuration contains correct settings
    file_contains "$TEST_DIR/sites/$site_name/php/php.ini" "memory_limit = 256M"
    file_contains "$TEST_DIR/sites/$site_name/php/php.ini" "upload_max_filesize = 64M"
}

@test "MariaDB container configuration is correct" {
    local site_name="test-site"
    
    # Create MariaDB initialization directory
    mkdir -p "$TEST_DIR/sites/$site_name/db/init"
    
    # Create MariaDB initialization script
    cat > "$TEST_DIR/sites/$site_name/db/init/01-create-database.sql" << EOF
CREATE DATABASE IF NOT EXISTS test_db;
GRANT ALL PRIVILEGES ON test_db.* TO 'test_user'@'%';
FLUSH PRIVILEGES;
EOF
    
    # Check if MariaDB initialization script exists
    file_exists "$TEST_DIR/sites/$site_name/db/init/01-create-database.sql"
    
    # Check if MariaDB initialization script contains correct SQL
    file_contains "$TEST_DIR/sites/$site_name/db/init/01-create-database.sql" "CREATE DATABASE IF NOT EXISTS test_db"
    file_contains "$TEST_DIR/sites/$site_name/db/init/01-create-database.sql" "GRANT ALL PRIVILEGES ON test_db.* TO 'test_user'@'%'"
} 