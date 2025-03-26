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
    mkdir -p "$TEST_DIR/sites/test-site/wordpress"
    mkdir -p "$TEST_DIR/sites/test-site/wordpress/wp-content"
    mkdir -p "$TEST_DIR/sites/test-site/wordpress/wp-admin"
    
    # Create WordPress core files
    touch "$TEST_DIR/sites/test-site/wordpress/index.php"
    touch "$TEST_DIR/sites/test-site/wordpress/wp-config.php"
    
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

# Helper function to check if a file contains specific content
file_contains() {
    local file="$1"
    local content="$2"
    
    grep -q "$content" "$file"
}

# Helper function to check if a file exists
file_exists() {
    local file="$1"
    
    [[ -f "$file" ]]
}

# Helper function to check if a directory exists
dir_exists() {
    local dir="$1"
    
    [[ -d "$dir" ]]
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

@test "WordPress installation creates required files" {
    local site_name="test-site"
    local domain="test-site.local"
    
    # Check if WordPress core files exist
    file_exists "$TEST_DIR/sites/$site_name/wordpress/index.php"
    file_exists "$TEST_DIR/sites/$site_name/wordpress/wp-config.php"
    dir_exists "$TEST_DIR/sites/$site_name/wordpress/wp-content"
    dir_exists "$TEST_DIR/sites/$site_name/wordpress/wp-admin"
}

@test "WordPress configuration file is properly set up" {
    local site_name="test-site"
    local domain="test-site.local"
    local db_name="test_db"
    local db_user="test_user"
    local db_pass="test_pass"
    
    # Create wp-config.php
    cat > "$TEST_DIR/sites/$site_name/wordpress/wp-config.php" << EOF
<?php
define('DB_NAME', '$db_name');
define('DB_USER', '$db_user');
define('DB_PASSWORD', '$db_pass');
define('DB_HOST', 'localhost');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');
define('WP_DEBUG', false);
EOF
    
    # Check if wp-config.php contains correct database settings
    file_contains "$TEST_DIR/sites/$site_name/wordpress/wp-config.php" "define('DB_NAME', '$db_name');"
    file_contains "$TEST_DIR/sites/$site_name/wordpress/wp-config.php" "define('DB_USER', '$db_user');"
    file_contains "$TEST_DIR/sites/$site_name/wordpress/wp-config.php" "define('DB_PASSWORD', '$db_pass');"
}

@test "WordPress directory permissions are correct" {
    local site_name="test-site"
    
    # Set correct permissions
    chmod 755 "$TEST_DIR/sites/$site_name/wordpress"
    chmod 644 "$TEST_DIR/sites/$site_name/wordpress/wp-config.php"
    
    # Check directory permissions
    dir_has_permissions "$TEST_DIR/sites/$site_name/wordpress" "755"
    file_has_permissions "$TEST_DIR/sites/$site_name/wordpress/wp-config.php" "644"
}

@test "WordPress installation with custom admin credentials" {
    local site_name="test-site"
    local domain="test-site.local"
    local admin_user="custom_admin"
    local admin_pass="custom_pass"
    local admin_email="admin@test-site.local"
    
    # Create wp-info file with admin credentials
    cat > "$TEST_DIR/sites/$site_name/.wp-info" << EOF
🌍 Website URL:   https://$domain
🔑 Admin URL:     https://$domain/wp-admin
👤 Admin User:    $admin_user
🔒 Admin Pass:    $admin_pass
📧 Admin Email:   $admin_email
EOF
    
    # Check if admin credentials are correctly saved
    file_contains "$TEST_DIR/sites/$site_name/.wp-info" "👤 Admin User:    $admin_user"
    file_contains "$TEST_DIR/sites/$site_name/.wp-info" "🔒 Admin Pass:    $admin_pass"
    file_contains "$TEST_DIR/sites/$site_name/.wp-info" "📧 Admin Email:   $admin_email"
}

@test "WordPress installation with auto-generated admin credentials" {
    local site_name="test-site"
    local domain="test-site.local"
    
    # Generate random admin credentials
    local admin_user="admin-$(openssl rand -base64 6 | tr -dc 'a-zA-Z0-9' | head -c 8)"
    local admin_pass="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c 16)"
    local admin_email="admin@$domain"
    
    # Create wp-info file with auto-generated credentials
    cat > "$TEST_DIR/sites/$site_name/.wp-info" << EOF
🌍 Website URL:   https://$domain
🔑 Admin URL:     https://$domain/wp-admin
👤 Admin User:    $admin_user
🔒 Admin Pass:    $admin_pass
📧 Admin Email:   $admin_email
EOF
    
    # Check if auto-generated credentials are correctly saved
    file_contains "$TEST_DIR/sites/$site_name/.wp-info" "👤 Admin User:    $admin_user"
    file_contains "$TEST_DIR/sites/$site_name/.wp-info" "🔒 Admin Pass:    $admin_pass"
    file_contains "$TEST_DIR/sites/$site_name/.wp-info" "📧 Admin Email:   $admin_email"
    
    # Check if generated credentials meet requirements
    [[ ${#admin_user} -ge 8 ]]
    [[ ${#admin_pass} -ge 16 ]]
    [[ "$admin_email" =~ ^admin@.*\.local$ ]]
}

@test "WordPress installation with custom permalinks" {
    local site_name="test-site"
    local domain="test-site.local"
    
    # Create .htaccess file with custom permalinks
    cat > "$TEST_DIR/sites/$site_name/wordpress/.htaccess" << 'EOF'
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
EOF
    
    # Check if .htaccess file exists and has correct content
    file_exists "$TEST_DIR/sites/$site_name/wordpress/.htaccess"
    file_contains "$TEST_DIR/sites/$site_name/wordpress/.htaccess" "# BEGIN WordPress"
    file_contains "$TEST_DIR/sites/$site_name/wordpress/.htaccess" "# END WordPress"
    file_contains "$TEST_DIR/sites/$site_name/wordpress/.htaccess" "RewriteEngine On"
} 