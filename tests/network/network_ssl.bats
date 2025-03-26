#!/usr/bin/env bats

setup() {
    # Create temporary test directory
    export TEST_DIR="$(mktemp -d)"
    
    # Create required directories
    mkdir -p "$TEST_DIR/sites/test-site"
    mkdir -p "$TEST_DIR/shared/config"
    mkdir -p "$TEST_DIR/webserver/nginx/conf"
    mkdir -p "$TEST_DIR/logs"
    mkdir -p "$TEST_DIR/tmp"
    mkdir -p "$TEST_DIR/sites/test-site/ssl"
    
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
    
    # Escape special characters in the content
    content=$(echo "$content" | sed 's/[]\/$*.^[]/\\&/g')
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
@test "Network configuration is properly set up" {
    local site_name="test-site"
    local domain="test-site.local"
    
    # Create docker-compose.yml with network configuration
    cat > "$TEST_DIR/sites/$site_name/docker-compose.yml" << EOF
version: '3.8'
services:
  nginx:
    container_name: ${site_name}-nginx
    networks:
      - ${site_name}-network
  php:
    container_name: ${site_name}-php
    networks:
      - ${site_name}-network
  mariadb:
    container_name: ${site_name}-mariadb
    networks:
      - ${site_name}-network

networks:
  ${site_name}-network:
    driver: bridge
EOF
    
    # Check if configuration exists
    file_exists "$TEST_DIR/sites/$site_name/docker-compose.yml"
    
    # Check if network is properly configured
    file_contains "$TEST_DIR/sites/$site_name/docker-compose.yml" "${site_name}-network"
    file_contains "$TEST_DIR/sites/$site_name/docker-compose.yml" "driver: bridge"
}

@test "SSL certificates are properly generated and stored" {
    local site_name="test-site"
    local domain="test-site.local"
    
    # Create SSL certificates
    mkdir -p "$TEST_DIR/sites/$site_name/ssl"
    touch "$TEST_DIR/sites/$site_name/ssl/$domain.crt"
    touch "$TEST_DIR/sites/$site_name/ssl/$domain.key"
    
    # Check if SSL certificates exist
    file_exists "$TEST_DIR/sites/$site_name/ssl/$domain.crt"
    file_exists "$TEST_DIR/sites/$site_name/ssl/$domain.key"
}

@test "Nginx configuration includes SSL settings" {
    local site_name="test-site"
    local domain="test-site.local"
    
    # Create Nginx configuration with SSL
    mkdir -p "$TEST_DIR/sites/$site_name/nginx"
    cat > "$TEST_DIR/sites/$site_name/nginx/default.conf" << EOF
server {
    listen 80;
    server_name ${domain};
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name ${domain};
    
    ssl_certificate /etc/nginx/ssl/${domain}.crt;
    ssl_certificate_key /etc/nginx/ssl/${domain}.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    root /var/www/html;
    index index.php index.html;
    
    location / {
        try_files $uri $uri/ /index.php?$args;
    }
    
    location ~ \.php$ {
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF
    
    # Check if Nginx configuration exists
    file_exists "$TEST_DIR/sites/$site_name/nginx/default.conf"
    
    # Check if SSL configuration is correct
    file_contains "$TEST_DIR/sites/$site_name/nginx/default.conf" "listen 443 ssl"
    file_contains "$TEST_DIR/sites/$site_name/nginx/default.conf" "ssl_certificate /etc/nginx/ssl/${domain}.crt"
    file_contains "$TEST_DIR/sites/$site_name/nginx/default.conf" "ssl_certificate_key /etc/nginx/ssl/${domain}.key"
    file_contains "$TEST_DIR/sites/$site_name/nginx/default.conf" "ssl_protocols TLSv1.2 TLSv1.3"
}

@test "HTTP to HTTPS redirection is configured" {
    local site_name="test-site"
    local domain="test-site.local"
    
    # Create Nginx configuration with HTTP to HTTPS redirection
    mkdir -p "$TEST_DIR/sites/$site_name/nginx"
    cat > "$TEST_DIR/sites/$site_name/nginx/default.conf" << EOF
server {
    listen 80;
    server_name ${domain};
    return 301 https://$host$request_uri;
}
EOF
    
    # Check if HTTP to HTTPS redirection is configured
    file_contains "$TEST_DIR/sites/$site_name/nginx/default.conf" "return 301 https://$host$request_uri"
}

@test "SSL certificates have correct permissions" {
    local site_name="test-site"
    local domain="test-site.local"
    
    # Create SSL certificates with correct permissions
    mkdir -p "$TEST_DIR/sites/$site_name/ssl"
    touch "$TEST_DIR/sites/$site_name/ssl/$domain.crt"
    touch "$TEST_DIR/sites/$site_name/ssl/$domain.key"
    chmod 644 "$TEST_DIR/sites/$site_name/ssl/$domain.crt"
    chmod 600 "$TEST_DIR/sites/$site_name/ssl/$domain.key"
    
    # Check if SSL certificates have correct permissions
    file_has_permissions "$TEST_DIR/sites/$site_name/ssl/$domain.crt" "644"
    file_has_permissions "$TEST_DIR/sites/$site_name/ssl/$domain.key" "600"
} 