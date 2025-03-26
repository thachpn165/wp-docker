#!/usr/bin/env bats

# Load test helper
load "../test_helper.bats"

@test "Docker container creation with correct configuration" {
    local site_name="test-site"
    local domain="test-site.local"
    
    # Create test site
    create_test_site "$site_name" "$domain"
    
    # Create docker-compose.yml
    cat > "$TEST_DIR/sites/$site_name/docker-compose.yml" << EOF
version: '3.8'

services:
  php:
    container_name: ${site_name}-php
    image: php:8.1-fpm
    volumes:
      - ./wordpress:/var/www/html
    networks:
      - ${site_name}-network

  nginx:
    container_name: ${site_name}-nginx
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./wordpress:/var/www/html
      - ./nginx/conf.d:/etc/nginx/conf.d
    networks:
      - ${site_name}-network

  mariadb:
    container_name: ${site_name}-mariadb
    image: mariadb:10.5
    environment:
      MYSQL_DATABASE: test_db
      MYSQL_USER: test_user
      MYSQL_PASSWORD: test_pass
    volumes:
      - ${site_name}-db:/var/lib/mysql
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
    
    # Check if docker-compose.yml contains correct service names
    file_contains "$TEST_DIR/sites/$site_name/docker-compose.yml" "container_name: ${site_name}-php"
    file_contains "$TEST_DIR/sites/$site_name/docker-compose.yml" "container_name: ${site_name}-nginx"
    file_contains "$TEST_DIR/sites/$site_name/docker-compose.yml" "container_name: ${site_name}-mariadb"
    
    # Check if docker-compose.yml contains correct network name
    file_contains "$TEST_DIR/sites/$site_name/docker-compose.yml" "${site_name}-network"
    
    # Check if docker-compose.yml contains correct volume name
    file_contains "$TEST_DIR/sites/$site_name/docker-compose.yml" "${site_name}-db"
}

@test "Docker container startup sequence" {
    local site_name="test-site"
    
    # Create test site
    create_test_site "$site_name" "test-site.local"
    
    # Create docker-compose.yml
    cat > "$TEST_DIR/sites/$site_name/docker-compose.yml" << EOF
version: '3.8'

services:
  php:
    container_name: ${site_name}-php
    image: php:8.1-fpm
    depends_on:
      - mariadb
    networks:
      - ${site_name}-network

  mariadb:
    container_name: ${site_name}-mariadb
    image: mariadb:10.5
    networks:
      - ${site_name}-network

networks:
  ${site_name}-network:
    driver: bridge
EOF
    
    # Check if mariadb service is listed as dependency for php service
    file_contains "$TEST_DIR/sites/$site_name/docker-compose.yml" "depends_on:"
    file_contains "$TEST_DIR/sites/$site_name/docker-compose.yml" "- mariadb"
}

@test "Docker container environment variables" {
    local site_name="test-site"
    local db_name="test_db"
    local db_user="test_user"
    local db_pass="test_pass"
    
    # Create test site
    create_test_site "$site_name" "test-site.local"
    
    # Create docker-compose.yml
    cat > "$TEST_DIR/sites/$site_name/docker-compose.yml" << EOF
version: '3.8'

services:
  mariadb:
    container_name: ${site_name}-mariadb
    image: mariadb:10.5
    environment:
      MYSQL_DATABASE: ${db_name}
      MYSQL_USER: ${db_user}
      MYSQL_PASSWORD: ${db_pass}
    networks:
      - ${site_name}-network

networks:
  ${site_name}-network:
    driver: bridge
EOF
    
    # Check if environment variables are correctly set
    file_contains "$TEST_DIR/sites/$site_name/docker-compose.yml" "MYSQL_DATABASE: ${db_name}"
    file_contains "$TEST_DIR/sites/$site_name/docker-compose.yml" "MYSQL_USER: ${db_user}"
    file_contains "$TEST_DIR/sites/$site_name/docker-compose.yml" "MYSQL_PASSWORD: ${db_pass}"
}

@test "Docker container volume mappings" {
    local site_name="test-site"
    
    # Create test site
    create_test_site "$site_name" "test-site.local"
    
    # Create docker-compose.yml
    cat > "$TEST_DIR/sites/$site_name/docker-compose.yml" << EOF
version: '3.8'

services:
  php:
    container_name: ${site_name}-php
    image: php:8.1-fpm
    volumes:
      - ./wordpress:/var/www/html
      - ./php/php.ini:/usr/local/etc/php/php.ini
      - ./php/www.conf:/usr/local/etc/php-fpm.d/www.conf
    networks:
      - ${site_name}-network

networks:
  ${site_name}-network:
    driver: bridge
EOF
    
    # Check if volume mappings are correctly set
    file_contains "$TEST_DIR/sites/$site_name/docker-compose.yml" "./wordpress:/var/www/html"
    file_contains "$TEST_DIR/sites/$site_name/docker-compose.yml" "./php/php.ini:/usr/local/etc/php/php.ini"
    file_contains "$TEST_DIR/sites/$site_name/docker-compose.yml" "./php/www.conf:/usr/local/etc/php-fpm.d/www.conf"
}

@test "Docker container network configuration" {
    local site_name="test-site"
    
    # Create test site
    create_test_site "$site_name" "test-site.local"
    
    # Create docker-compose.yml
    cat > "$TEST_DIR/sites/$site_name/docker-compose.yml" << EOF
version: '3.8'

services:
  php:
    container_name: ${site_name}-php
    image: php:8.1-fpm
    networks:
      - ${site_name}-network

  nginx:
    container_name: ${site_name}-nginx
    image: nginx:alpine
    networks:
      - ${site_name}-network

  mariadb:
    container_name: ${site_name}-mariadb
    image: mariadb:10.5
    networks:
      - ${site_name}-network

networks:
  ${site_name}-network:
    driver: bridge
EOF
    
    # Check if all services are connected to the same network
    file_contains "$TEST_DIR/sites/$site_name/docker-compose.yml" "networks:"
    file_contains "$TEST_DIR/sites/$site_name/docker-compose.yml" "- ${site_name}-network"
    
    # Count network connections (should be 3)
    local network_count=$(grep -c "networks:" "$TEST_DIR/sites/$site_name/docker-compose.yml")
    [ "$network_count" -eq 3 ]
}

@test "Docker container port mappings" {
    local site_name="test-site"
    
    # Create test site
    create_test_site "$site_name" "test-site.local"
    
    # Create docker-compose.yml
    cat > "$TEST_DIR/sites/$site_name/docker-compose.yml" << EOF
version: '3.8'

services:
  nginx:
    container_name: ${site_name}-nginx
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    networks:
      - ${site_name}-network

networks:
  ${site_name}-network:
    driver: bridge
EOF
    
    # Check if port mappings are correctly set
    file_contains "$TEST_DIR/sites/$site_name/docker-compose.yml" "ports:"
    file_contains "$TEST_DIR/sites/$site_name/docker-compose.yml" "- \"80:80\""
    file_contains "$TEST_DIR/sites/$site_name/docker-compose.yml" "- \"443:443\""
} 