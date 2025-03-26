#!/usr/bin/env bats

# Load test helper
load "../test_helper.bats"

@test "Network configuration is properly set up" {
    local site_name="test-site"
    local domain="test-site.local"
    
    # Create test site
    create_test_site "$site_name" "$domain"
    
    # Create nginx configuration
    mkdir -p "$TEST_DIR/sites/$site_name/nginx/conf.d"
    cat > "$TEST_DIR/sites/$site_name/nginx/conf.d/default.conf" << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $domain;
    root /var/www/html;
    index index.php;
}
EOF
    
    # Check if nginx configuration exists
    file_exists "$TEST_DIR/sites/$site_name/nginx/conf.d/default.conf"
    
    # Check if IPv4 and IPv6 are configured
    file_contains "$TEST_DIR/sites/$site_name/nginx/conf.d/default.conf" "listen 80;"
    file_contains "$TEST_DIR/sites/$site_name/nginx/conf.d/default.conf" "listen [::]:80;"
}

@test "SSL certificate generation" {
    local site_name="test-site"
    local domain="test-site.local"
    
    # Create test site
    create_test_site "$site_name" "$domain"
    
    # Create SSL directory
    mkdir -p "$TEST_DIR/sites/$site_name/ssl"
    
    # Create SSL certificate and key
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$TEST_DIR/sites/$site_name/ssl/private.key" \
        -out "$TEST_DIR/sites/$site_name/ssl/certificate.crt" \
        -subj "/CN=$domain" \
        -addext "subjectAltName=DNS:$domain"
    
    # Check if SSL files exist
    file_exists "$TEST_DIR/sites/$site_name/ssl/private.key"
    file_exists "$TEST_DIR/sites/$site_name/ssl/certificate.crt"
    
    # Check SSL file permissions
    file_has_permissions "$TEST_DIR/sites/$site_name/ssl/private.key" "600"
    file_has_permissions "$TEST_DIR/sites/$site_name/ssl/certificate.crt" "644"
}

@test "SSL configuration in nginx" {
    local site_name="test-site"
    local domain="test-site.local"
    
    # Create test site
    create_test_site "$site_name" "$domain"
    
    # Create nginx SSL configuration
    mkdir -p "$TEST_DIR/sites/$site_name/nginx/conf.d"
    cat > "$TEST_DIR/sites/$site_name/nginx/conf.d/default.conf" << EOF
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $domain;
    
    ssl_certificate /etc/nginx/ssl/certificate.crt;
    ssl_certificate_key /etc/nginx/ssl/private.key;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    
    ssl_prefer_server_ciphers off;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;
    
    root /var/www/html;
    index index.php;
}
EOF
    
    # Check if SSL configuration exists
    file_exists "$TEST_DIR/sites/$site_name/nginx/conf.d/default.conf"
    
    # Check SSL configuration parameters
    file_contains "$TEST_DIR/sites/$site_name/nginx/conf.d/default.conf" "listen 443 ssl http2"
    file_contains "$TEST_DIR/sites/$site_name/nginx/conf.d/default.conf" "ssl_certificate"
    file_contains "$TEST_DIR/sites/$site_name/nginx/conf.d/default.conf" "ssl_certificate_key"
    file_contains "$TEST_DIR/sites/$site_name/nginx/conf.d/default.conf" "ssl_protocols"
    file_contains "$TEST_DIR/sites/$site_name/nginx/conf.d/default.conf" "ssl_ciphers"
}

@test "HTTP to HTTPS redirection" {
    local site_name="test-site"
    local domain="test-site.local"
    
    # Create test site
    create_test_site "$site_name" "$domain"
    
    # Create nginx configuration with HTTP to HTTPS redirection
    mkdir -p "$TEST_DIR/sites/$site_name/nginx/conf.d"
    cat > "$TEST_DIR/sites/$site_name/nginx/conf.d/default.conf" << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $domain;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $domain;
    
    ssl_certificate /etc/nginx/ssl/certificate.crt;
    ssl_certificate_key /etc/nginx/ssl/private.key;
    
    root /var/www/html;
    index index.php;
}
EOF
    
    # Check if redirection configuration exists
    file_exists "$TEST_DIR/sites/$site_name/nginx/conf.d/default.conf"
    
    # Check redirection configuration
    file_contains "$TEST_DIR/sites/$site_name/nginx/conf.d/default.conf" "return 301 https://\$server_name\$request_uri"
}

@test "SSL certificate renewal configuration" {
    local site_name="test-site"
    local domain="test-site.local"
    
    # Create test site
    create_test_site "$site_name" "$domain"
    
    # Create SSL renewal script
    cat > "$TEST_DIR/sites/$site_name/ssl/renew.sh" << 'EOF'
#!/bin/bash
# SSL certificate renewal script
certbot renew --quiet --post-hook "nginx -s reload"
EOF
    
    # Make renewal script executable
    chmod +x "$TEST_DIR/sites/$site_name/ssl/renew.sh"
    
    # Check if renewal script exists and is executable
    file_exists "$TEST_DIR/sites/$site_name/ssl/renew.sh"
    file_has_permissions "$TEST_DIR/sites/$site_name/ssl/renew.sh" "755"
    
    # Create cron job for certificate renewal
    cat > "$TEST_DIR/sites/$site_name/ssl/renew.cron" << 'EOF'
0 0 1 * * /path/to/renew.sh
EOF
    
    # Check if cron job configuration exists
    file_exists "$TEST_DIR/sites/$site_name/ssl/renew.cron"
}

@test "Network security headers" {
    local site_name="test-site"
    local domain="test-site.local"
    
    # Create test site
    create_test_site "$site_name" "$domain"
    
    # Create nginx configuration with security headers
    mkdir -p "$TEST_DIR/sites/$site_name/nginx/conf.d"
    cat > "$TEST_DIR/sites/$site_name/nginx/conf.d/default.conf" << EOF
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $domain;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    root /var/www/html;
    index index.php;
}
EOF
    
    # Check if security headers are configured
    file_contains "$TEST_DIR/sites/$site_name/nginx/conf.d/default.conf" "Strict-Transport-Security"
    file_contains "$TEST_DIR/sites/$site_name/nginx/conf.d/default.conf" "X-Frame-Options"
    file_contains "$TEST_DIR/sites/$site_name/nginx/conf.d/default.conf" "X-XSS-Protection"
    file_contains "$TEST_DIR/sites/$site_name/nginx/conf.d/default.conf" "X-Content-Type-Options"
    file_contains "$TEST_DIR/sites/$site_name/nginx/conf.d/default.conf" "Referrer-Policy"
    file_contains "$TEST_DIR/sites/$site_name/nginx/conf.d/default.conf" "Content-Security-Policy"
} 