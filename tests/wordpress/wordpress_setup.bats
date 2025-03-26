#!/usr/bin/env bats

# Load test helper
load "../test_helper.bats"

setup() {
    # Create WordPress directory structure
    local site_name="test-site"
    local wordpress_dir="$TEST_DIR/sites/$site_name/wordpress"
    
    # Create WordPress directory and its subdirectories
    mkdir -p "$wordpress_dir"
    mkdir -p "$wordpress_dir/wp-content"
    mkdir -p "$wordpress_dir/wp-admin"
    
    # Create WordPress core files
    touch "$wordpress_dir/index.php"
    touch "$wordpress_dir/wp-config.php"
}

@test "WordPress installation creates required files" {
    local site_name="test-site"
    local domain="test-site.local"
    
    # Create test site
    create_test_site "$site_name" "$domain"
    
    # Check if WordPress core files exist
    file_exists "$TEST_DIR/sites/$site_name/wordpress/index.php"
    file_exists "$TEST_DIR/sites/$site_name/wordpress/wp-config.php"
    file_exists "$TEST_DIR/sites/$site_name/wordpress/wp-content"
    file_exists "$TEST_DIR/sites/$site_name/wordpress/wp-admin"
}

@test "WordPress configuration file is properly set up" {
    local site_name="test-site"
    local domain="test-site.local"
    local db_name="test_db"
    local db_user="test_user"
    local db_pass="test_pass"
    
    # Create test site
    create_test_site "$site_name" "$domain"
    
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
    
    # Create test site and WordPress directory
    create_test_site "$site_name" "test-site.local"
    
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
    
    # Create test site
    create_test_site "$site_name" "$domain"
    
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
    
    # Create test site
    create_test_site "$site_name" "$domain"
    
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
    
    # Create test site
    create_test_site "$site_name" "$domain"
    
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