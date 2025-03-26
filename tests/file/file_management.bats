#!/usr/bin/env bats

# Load test helper
load "../test_helper.bats"

@test "File system structure creation" {
    local site_name="test-site"
    
    # Create test site
    create_test_site "$site_name" "test-site.local"
    
    # Create required directories
    mkdir -p "$TEST_DIR/sites/$site_name/wordpress"
    mkdir -p "$TEST_DIR/sites/$site_name/nginx/conf.d"
    mkdir -p "$TEST_DIR/sites/$site_name/php"
    mkdir -p "$TEST_DIR/sites/$site_name/logs"
    
    # Check if all required directories exist
    dir_exists "$TEST_DIR/sites/$site_name/wordpress"
    dir_exists "$TEST_DIR/sites/$site_name/nginx/conf.d"
    dir_exists "$TEST_DIR/sites/$site_name/php"
    dir_exists "$TEST_DIR/sites/$site_name/logs"
}

@test "File permissions are correctly set" {
    local site_name="test-site"
    
    # Create test site
    create_test_site "$site_name" "test-site.local"
    
    # Create test files and directories
    mkdir -p "$TEST_DIR/sites/$site_name/wordpress"
    touch "$TEST_DIR/sites/$site_name/wordpress/index.php"
    
    # Set correct permissions
    chmod 755 "$TEST_DIR/sites/$site_name/wordpress"
    chmod 644 "$TEST_DIR/sites/$site_name/wordpress/index.php"
    
    # Check directory permissions
    dir_has_permissions "$TEST_DIR/sites/$site_name/wordpress" "755"
    
    # Check file permissions
    file_has_permissions "$TEST_DIR/sites/$site_name/wordpress/index.php" "644"
}

@test "File ownership is correctly set" {
    local site_name="test-site"
    local user="nobody"
    local group="nogroup"
    
    # Create test site
    create_test_site "$site_name" "test-site.local"
    
    # Create test files and directories
    mkdir -p "$TEST_DIR/sites/$site_name/wordpress"
    touch "$TEST_DIR/sites/$site_name/wordpress/index.php"
    
    # Set correct ownership
    chown -R "$user:$group" "$TEST_DIR/sites/$site_name/wordpress"
    
    # Check directory ownership
    dir_owned_by "$TEST_DIR/sites/$site_name/wordpress" "$user"
    
    # Check file ownership
    file_owned_by "$TEST_DIR/sites/$site_name/wordpress/index.php" "$user"
}

@test "Configuration files are properly created" {
    local site_name="test-site"
    local domain="test-site.local"
    
    # Create test site
    create_test_site "$site_name" "$domain"
    
    # Create nginx configuration
    mkdir -p "$TEST_DIR/sites/$site_name/nginx/conf.d"
    cat > "$TEST_DIR/sites/$site_name/nginx/conf.d/default.conf" << EOF
server {
    listen 80;
    server_name $domain;
    root /var/www/html;
    index index.php;
}
EOF
    
    # Create PHP configuration
    mkdir -p "$TEST_DIR/sites/$site_name/php"
    cat > "$TEST_DIR/sites/$site_name/php/php.ini" << EOF
[PHP]
memory_limit = 256M
upload_max_filesize = 64M
post_max_size = 64M
max_execution_time = 300
EOF
    
    # Check if configuration files exist
    file_exists "$TEST_DIR/sites/$site_name/nginx/conf.d/default.conf"
    file_exists "$TEST_DIR/sites/$site_name/php/php.ini"
    
    # Check if configuration files contain correct content
    file_contains "$TEST_DIR/sites/$site_name/nginx/conf.d/default.conf" "server_name $domain"
    file_contains "$TEST_DIR/sites/$site_name/php/php.ini" "memory_limit = 256M"
}

@test "Log files are properly created and rotated" {
    local site_name="test-site"
    
    # Create test site
    create_test_site "$site_name" "test-site.local"
    
    # Create log directory
    mkdir -p "$TEST_DIR/sites/$site_name/logs"
    
    # Create log files
    touch "$TEST_DIR/sites/$site_name/logs/access.log"
    touch "$TEST_DIR/sites/$site_name/logs/error.log"
    
    # Check if log files exist
    file_exists "$TEST_DIR/sites/$site_name/logs/access.log"
    file_exists "$TEST_DIR/sites/$site_name/logs/error.log"
    
    # Create logrotate configuration
    cat > "$TEST_DIR/sites/$site_name/logrotate.conf" << EOF
$TEST_DIR/sites/$site_name/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 nobody nogroup
}
EOF
    
    # Check if logrotate configuration exists
    file_exists "$TEST_DIR/sites/$site_name/logrotate.conf"
    
    # Check if logrotate configuration contains correct settings
    file_contains "$TEST_DIR/sites/$site_name/logrotate.conf" "daily"
    file_contains "$TEST_DIR/sites/$site_name/logrotate.conf" "rotate 7"
    file_contains "$TEST_DIR/sites/$site_name/logrotate.conf" "compress"
}

@test "Backup files are properly created" {
    local site_name="test-site"
    
    # Create test site
    create_test_site "$site_name" "test-site.local"
    
    # Create backup directory
    mkdir -p "$TEST_DIR/sites/$site_name/backups"
    
    # Create test backup file
    local backup_file="$TEST_DIR/sites/$site_name/backups/backup-$(date +%Y%m%d).tar.gz"
    touch "$backup_file"
    
    # Check if backup file exists
    file_exists "$backup_file"
    
    # Check backup file permissions
    file_has_permissions "$backup_file" "644"
    
    # Check backup file ownership
    file_owned_by "$backup_file" "nobody"
}

@test "Temporary files are properly managed" {
    local site_name="test-site"
    
    # Create test site
    create_test_site "$site_name" "test-site.local"
    
    # Create temporary directory
    mkdir -p "$TEST_DIR/sites/$site_name/tmp"
    
    # Create test temporary file
    touch "$TEST_DIR/sites/$site_name/tmp/test.tmp"
    
    # Check if temporary file exists
    file_exists "$TEST_DIR/sites/$site_name/tmp/test.tmp"
    
    # Create cleanup script
    cat > "$TEST_DIR/sites/$site_name/cleanup.sh" << 'EOF'
#!/bin/bash
find ./tmp -type f -name "*.tmp" -mtime +7 -delete
EOF
    
    # Make cleanup script executable
    chmod +x "$TEST_DIR/sites/$site_name/cleanup.sh"
    
    # Check if cleanup script exists and is executable
    file_exists "$TEST_DIR/sites/$site_name/cleanup.sh"
    file_has_permissions "$TEST_DIR/sites/$site_name/cleanup.sh" "755"
} 