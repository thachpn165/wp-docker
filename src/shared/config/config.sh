# =====================================
# ⚙️ CẤU HÌNH TOÀN CỤC - config.sh
# =====================================

# ==== Tự động xác định PROJECT_ROOT dù là src/ hay bản release ====
SCRIPT_PATH="${BASH_SOURCE[0]}"
CONFIG_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

# Nếu nằm trong src/, lùi lên để tới repo gốc
if [[ "$CONFIG_DIR" == */src/shared/config ]]; then
  PROJECT_ROOT="$(cd "$CONFIG_DIR/../../.." && pwd)"
else
  PROJECT_ROOT="$(cd "$CONFIG_DIR/../.." && pwd)"
fi

# ==== Nếu có thư mục src/ thì là môi trường DEV
if [[ -d "$PROJECT_ROOT/src" ]]; then
  BASE_DIR="$PROJECT_ROOT/src"
else
  BASE_DIR="$PROJECT_ROOT"
fi

# ==== Các thư mục chính ====
SITES_DIR="$BASE_DIR/sites"
TEMPLATES_DIR="$BASE_DIR/shared/templates"
CONFIG_DIR="$BASE_DIR/shared/config"
SCRIPTS_DIR="$BASE_DIR/shared/scripts"
FUNCTIONS_DIR="$SCRIPTS_DIR/functions"
WP_SCRIPTS_DIR="$SCRIPTS_DIR/wp-scripts"
WEBSITE_MGMT_DIR="$SCRIPTS_DIR/website-management"
WORDPRESS_TOOLS_DIR="$SCRIPTS_DIR/wordpress-tools"
SYSTEM_TOOLS_FUNC_DIR="$FUNCTIONS_DIR/system-tools"
SCRIPTS_FUNCTIONS_DIR="$FUNCTIONS_DIR"
TMP_DIR="$PROJECT_ROOT/tmp"
# ==== Webserver (NGINX) ====
NGINX_PROXY_DIR="$BASE_DIR/webserver/nginx"
PROXY_CONF_DIR="$NGINX_PROXY_DIR/conf.d"
NGINX_SCRIPTS_DIR="$NGINX_PROXY_DIR/scripts"
SSL_DIR="$NGINX_PROXY_DIR/ssl"

# ==== Script tiện ích ====
SETUP_WORDPRESS_SCRIPT="$WP_SCRIPTS_DIR/wp-setup.sh"
PHP_USER="nobody"

# ==== Cấu hình mạng & container ====
DOCKER_NETWORK="proxy_network"
NGINX_PROXY_CONTAINER="nginx-proxy"

# ==== Màu sắc terminal ====
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# ==== Rclone ====
RCLONE_CONFIG_DIR="$CONFIG_DIR/rclone"
RCLONE_CONFIG_FILE="$RCLONE_CONFIG_DIR/rclone.conf"

# ==== Import các function utils ====
source "$FUNCTIONS_DIR/system_utils.sh"
source "$FUNCTIONS_DIR/docker_utils.sh"
source "$FUNCTIONS_DIR/file_utils.sh"
source "$FUNCTIONS_DIR/network_utils.sh"
source "$FUNCTIONS_DIR/ssl_utils.sh"
source "$FUNCTIONS_DIR/wp_utils.sh"
source "$FUNCTIONS_DIR/php_utils.sh"
source "$FUNCTIONS_DIR/db_utils.sh"
source "$FUNCTIONS_DIR/website_utils.sh"
source "$FUNCTIONS_DIR/misc_utils.sh"
source "$FUNCTIONS_DIR/nginx_utils.sh"
