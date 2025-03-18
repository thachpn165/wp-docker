#!/bin/bash

# Lấy thư mục thực tế của script, đảm bảo đúng đường dẫn
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../" && pwd)"

# Thư mục chứa các site
SITES_DIR="$PROJECT_ROOT/sites"

# Thư mục chứa template cấu hình
TEMPLATES_DIR="$PROJECT_ROOT/shared/templates"

# Thư mục chứa script
SCRIPTS_DIR="$PROJECT_ROOT/shared/scripts/wp-scripts"

# Đường dẫn script cài đặt WordPress
SETUP_WORDPRESS_SCRIPT="$SCRIPTS_DIR/setup-wordpress.sh"

# Đường dẫn script khởi động lại Nginx Proxy
PROXY_SCRIPT="$PROJECT_ROOT/nginx-proxy/restart-nginx-proxy.sh"
PROXY_CONF_DIR="$PROJECT_ROOT/nginx-proxy/conf.d"
SITE_CONF_FILE="$PROXY_CONF_DIR/$site_name.conf"
SSL_DIR="$PROJECT_ROOT/nginx-proxy/ssl"

# Debug
echo -e "${YELLOW}🔍 Debug: PROJECT_ROOT = $PROJECT_ROOT ${NC}"
echo -e "${YELLOW}🔍 Debug: SITES_DIR = $SITES_DIR ${NC}"
echo -e "${YELLOW}🔍 Debug: TEMPLATES_DIR = $TEMPLATES_DIR ${NC}"
