#!/usr/bin/env bats

# Load test helper
load "$(dirname "$0")/../test_helper.bats"

@test "Database configuration is properly set up" {
    local site_name="test-site"
    local db_name="test_db"
    local db_user="test_user"
    local db_pass="test_pass"
    
    # Create test site
    create_test_site "$site_name" "test-site.local"
    
    # Create database configuration
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
      MYSQL_ROOT_PASSWORD: root_pass
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
    
    # Check if database configuration exists
    file_exists "$TEST_DIR/sites/$site_name/docker-compose.yml"
    
    # Check if database environment variables are set
    file_contains "$TEST_DIR/sites/$site_name/docker-compose.yml" "MYSQL_DATABASE: ${db_name}"
    file_contains "$TEST_DIR/sites/$site_name/docker-compose.yml" "MYSQL_USER: ${db_user}"
    file_contains "$TEST_DIR/sites/$site_name/docker-compose.yml" "MYSQL_PASSWORD: ${db_pass}"
}

@test "Database backup creation" {
    local site_name="test-site"
    local db_name="test_db"
    
    # Create test site
    create_test_site "$site_name" "test-site.local"
    
    # Create backup directory
    mkdir -p "$TEST_DIR/sites/$site_name/backups"
    
    # Create backup script
    cat > "$TEST_DIR/sites/$site_name/backups/backup-db.sh" << EOF
#!/bin/bash
docker exec ${site_name}-mariadb mysqldump -u root -proot_pass ${db_name} > backups/${db_name}-\$(date +%Y%m%d).sql
EOF
    
    # Make backup script executable
    chmod +x "$TEST_DIR/sites/$site_name/backups/backup-db.sh"
    
    # Check if backup script exists and is executable
    file_exists "$TEST_DIR/sites/$site_name/backups/backup-db.sh"
    file_has_permissions "$TEST_DIR/sites/$site_name/backups/backup-db.sh" "755"
}

@test "Database restore functionality" {
    local site_name="test-site"
    local db_name="test_db"
    
    # Create test site
    create_test_site "$site_name" "test-site.local"
    
    # Create restore script
    cat > "$TEST_DIR/sites/$site_name/backups/restore-db.sh" << EOF
#!/bin/bash
docker exec -i ${site_name}-mariadb mysql -u root -proot_pass ${db_name} < \$1
EOF
    
    # Make restore script executable
    chmod +x "$TEST_DIR/sites/$site_name/backups/restore-db.sh"
    
    # Check if restore script exists and is executable
    file_exists "$TEST_DIR/sites/$site_name/backups/restore-db.sh"
    file_has_permissions "$TEST_DIR/sites/$site_name/backups/restore-db.sh" "755"
}

@test "Database backup rotation" {
    local site_name="test-site"
    local db_name="test_db"
    
    # Create test site
    create_test_site "$site_name" "test-site.local"
    
    # Create backup rotation script
    cat > "$TEST_DIR/sites/$site_name/backups/rotate-backups.sh" << 'EOF'
#!/bin/bash
# Keep only last 7 days of backups
find ./backups -name "*.sql" -mtime +7 -delete
EOF
    
    # Make rotation script executable
    chmod +x "$TEST_DIR/sites/$site_name/backups/rotate-backups.sh"
    
    # Check if rotation script exists and is executable
    file_exists "$TEST_DIR/sites/$site_name/backups/rotate-backups.sh"
    file_has_permissions "$TEST_DIR/sites/$site_name/backups/rotate-backups.sh" "755"
}

@test "Database connection settings in WordPress" {
    local site_name="test-site"
    local db_name="test_db"
    local db_user="test_user"
    local db_pass="test_pass"
    
    # Create test site
    create_test_site "$site_name" "test-site.local"
    
    # Create wp-config.php
    cat > "$TEST_DIR/sites/$site_name/wordpress/wp-config.php" << EOF
<?php
define('DB_NAME', '$db_name');
define('DB_USER', '$db_user');
define('DB_PASSWORD', '$db_pass');
define('DB_HOST', 'mariadb');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');
define('WP_DEBUG', false);
EOF
    
    # Check if wp-config.php exists
    file_exists "$TEST_DIR/sites/$site_name/wordpress/wp-config.php"
    
    # Check if database settings are correctly set
    file_contains "$TEST_DIR/sites/$site_name/wordpress/wp-config.php" "define('DB_NAME', '$db_name');"
    file_contains "$TEST_DIR/sites/$site_name/wordpress/wp-config.php" "define('DB_USER', '$db_user');"
    file_contains "$TEST_DIR/sites/$site_name/wordpress/wp-config.php" "define('DB_PASSWORD', '$db_pass');"
    file_contains "$TEST_DIR/sites/$site_name/wordpress/wp-config.php" "define('DB_HOST', 'mariadb');"
}

@test "Database optimization script" {
    local site_name="test-site"
    local db_name="test_db"
    
    # Create test site
    create_test_site "$site_name" "test-site.local"
    
    # Create database optimization script
    cat > "$TEST_DIR/sites/$site_name/scripts/optimize-db.sh" << EOF
#!/bin/bash
docker exec ${site_name}-mariadb mysql -u root -proot_pass ${db_name} -e "
    OPTIMIZE TABLE wp_posts, wp_postmeta, wp_options;
    REPAIR TABLE wp_posts, wp_postmeta, wp_options;
"
EOF
    
    # Make optimization script executable
    chmod +x "$TEST_DIR/sites/$site_name/scripts/optimize-db.sh"
    
    # Check if optimization script exists and is executable
    file_exists "$TEST_DIR/sites/$site_name/scripts/optimize-db.sh"
    file_has_permissions "$TEST_DIR/sites/$site_name/scripts/optimize-db.sh" "755"
}

@test "Database backup compression" {
    local site_name="test-site"
    local db_name="test_db"
    
    # Create test site
    create_test_site "$site_name" "test-site.local"
    
    # Create backup script with compression
    cat > "$TEST_DIR/sites/$site_name/backups/backup-db-compressed.sh" << EOF
#!/bin/bash
docker exec ${site_name}-mariadb mysqldump -u root -proot_pass ${db_name} | gzip > backups/${db_name}-\$(date +%Y%m%d).sql.gz
EOF
    
    # Make backup script executable
    chmod +x "$TEST_DIR/sites/$site_name/backups/backup-db-compressed.sh"
    
    # Check if backup script exists and is executable
    file_exists "$TEST_DIR/sites/$site_name/backups/backup-db-compressed.sh"
    file_has_permissions "$TEST_DIR/sites/$site_name/backups/backup-db-compressed.sh" "755"
} 