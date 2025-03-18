# **Đường dẫn thư mục chính**
CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
SITES_DIR="$PROJECT_ROOT/sites"
TEMPLATES_DIR="$PROJECT_ROOT/shared/templates"
CONFIG_DIR="$PROJECT_ROOT/shared/config"
SCRIPTS_DIR="$PROJECT_ROOT/shared/scripts"
FUNCTIONS_DIR="$SCRIPTS_DIR/functions"
WP_SCRIPTS_DIR="$SCRIPTS_DIR/wp-scripts"
WEBSITE_MGMT_DIR="$SCRIPTS_DIR/website-management"
NGINX_PROXY_DIR="$PROJECT_ROOT/nginx-proxy"
PROXY_CONF_DIR="$NGINX_PROXY_DIR/conf.d"
NGINX_SCRIPTS_DIR="$NGINX_PROXY_DIR/scripts"
SSL_DIR="$NGINX_PROXY_DIR/ssl"

# **Biến Script**
SETUP_WORDPRESS_SCRIPT="$WP_SCRIPTS_DIR/wp-setup.sh"
PROXY_SCRIPT="$NGINX_SCRIPTS_DIR/manage-nginx.sh"

# **Biến mạng**
DOCKER_NETWORK="proxy_network"

# **Biến container**
NGINX_PROXY_CONTAINER="nginx-proxy"

# **Cấu hình Container**
CONTAINER_PHP="${site_name}-php"
CONTAINER_DB="${site_name}-mariadb"

# **Cấu hình URL cho Website**
SITE_URL="https://$DOMAIN"

# **Import các function utilities**
source "$FUNCTIONS_DIR/system_utils.sh"
source "$FUNCTIONS_DIR/docker_utils.sh"
source "$FUNCTIONS_DIR/file_utils.sh"
source "$FUNCTIONS_DIR/network_utils.sh"
source "$FUNCTIONS_DIR/ssl_utils.sh"
source "$FUNCTIONS_DIR/wp_utils.sh"
source "$FUNCTIONS_DIR/php_utils.sh"