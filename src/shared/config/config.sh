# =====================================
# ⚙️ CẤU HÌNH TOÀN CỤC - config.sh
# =====================================

# ==== Tự động xác định BASE_DIR (gốc của mã nguồn) ====
SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
CONFIG_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

# Nếu là môi trường DEV: có thư mục src/ → BASE_DIR sẽ là /.../wp-docker-lemp/src
if [[ "$CONFIG_DIR" == */src/shared/config ]]; then
  BASE_DIR="$(cd "$CONFIG_DIR/../../.." && pwd)/src"
  DEV_MODE=true
else
  BASE_DIR="$(cd "$CONFIG_DIR/../.." && pwd)"
  DEV_MODE=false
fi

# ==== Các thư mục mã nguồn chính ====
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
export TEMPLATE_VERSION_FILE="$BASE_DIR/shared/templates/.template_version"
export TEMPLATE_CHANGELOG_FILE="$BASE_DIR/shared/templates/TEMPLATE_CHANGELOG.md"

# ==== Các thư mục dữ liệu (nằm trong src/) ====
TMP_DIR="$BASE_DIR/tmp"
LOGS_DIR="$BASE_DIR/logs"
ARCHIVES_DIR="$BASE_DIR/archives"


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
source "$FUNCTIONS_DIR/php/php_utils.sh"
source "$FUNCTIONS_DIR/db_utils.sh"
source "$FUNCTIONS_DIR/website_utils.sh"
source "$FUNCTIONS_DIR/misc_utils.sh"
source "$FUNCTIONS_DIR/nginx_utils.sh"
