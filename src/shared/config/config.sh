# =====================================
# ⚙️ GLOBAL CONFIGURATION - config.sh
# =====================================

# ==== Automatically determine BASE_DIR (root of the source code) ====
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
CONFIG_DIR="$(dirname "$SCRIPT_PATH")"

# If in DEV environment (src/ folder exists): BASE_DIR will be /.../wp-docker/src
if [[ "$CONFIG_DIR" == */src/shared/config ]]; then
  BASE_DIR="$(cd "$CONFIG_DIR/../../.." && pwd)/src"
  DEV_MODE=true
else
  BASE_DIR="$(cd "$CONFIG_DIR/../.." && pwd)"
  DEV_MODE=false
fi


# By default, TEST_MODE is false, only set to true when running tests
# When writing tests, set TEST_MODE=true to skip Docker checks
# Or always pass the checks by setting TEST_ALWAYS_READY=true
TEST_MODE="${TEST_MODE:-false}"
TEST_ALWAYS_READY="${TEST_ALWAYS_READY:-false}"

# ==== Core variables ====
INSTALL_DIR="${INSTALL_DIR:-/opt/wp-docker}"  # Installation directory
TMP_DIR="${TMP_DIR:-/tmp/wp-docker-update}"  # Temporary directory for updates
REPO_URL="${REPO_URL:-https://github.com/thachpn165/wp-docker}"  # Repository URL
ZIP_NAME="${ZIP_NAME:-wp-docker.zip}"  # Downloaded ZIP file name
CORE_VERSION_FILE="${CORE_VERSION_FILE:-version.txt}"  # Version file
CORE_TEMPLATE_VERSION_FILE="${CORE_TEMPLATE_VERSION_FILE:-shared/templates/.template_version}"  # Template version file
LOG_FILE="${LOG_FILE:-/tmp/update_wp_docker.log}"  # Log file location
CORE_LATEST_VERSION="${CORE_LATEST_VERSION:-https://raw.githubusercontent.com/thachpn165/wp-docker/main/src/version.txt}"

# ==== Core source directories ====
SITES_DIR="${SITES_DIR:-$BASE_DIR/sites}"  # Sites directory
TEMPLATES_DIR="${TEMPLATES_DIR:-$BASE_DIR/shared/templates}"  # Templates directory
CONFIG_DIR="${CONFIG_DIR:-$BASE_DIR/shared/config}"  # Configuration directory
SCRIPTS_DIR="${SCRIPTS_DIR:-$BASE_DIR/shared/scripts}"  # Scripts directory
CLI_DIR="${CLI_DIR:-$SCRIPTS_DIR/cli}"  # CLI scripts directory
MENU_DIR="$SCRIPTS_DIR/menu"
FUNCTIONS_DIR="${FUNCTIONS_DIR:-$SCRIPTS_DIR/functions}"  # Functions directory
WP_SCRIPTS_DIR="${WP_SCRIPTS_DIR:-$SCRIPTS_DIR/wp-scripts}"  # WP scripts directory
WEBSITE_MGMT_DIR="${WEBSITE_MGMT_DIR:-$SCRIPTS_DIR/website-management}"  # Website management scripts directory
WORDPRESS_TOOLS_DIR="${WORDPRESS_TOOLS_DIR:-$SCRIPTS_DIR/wordpress-tools}"  # WordPress tools directory
SYSTEM_TOOLS_FUNC_DIR="${SYSTEM_TOOLS_FUNC_DIR:-$FUNCTIONS_DIR/system-tools}"  # System tools function directory
SCRIPTS_FUNCTIONS_DIR="${SCRIPTS_FUNCTIONS_DIR:-$FUNCTIONS_DIR}"  # Functions directory for various scripts
export TEMPLATE_VERSION_FILE="${TEMPLATE_VERSION_FILE:-$BASE_DIR/shared/templates/.template_version}"  # Template version file export
export TEMPLATE_CHANGELOG_FILE="${TEMPLATE_CHANGELOG_FILE:-$BASE_DIR/shared/templates/TEMPLATE_CHANGELOG.md}"  # Template changelog file export

# ==== Data directories (within src/) ====
TMP_DIR="${TMP_DIR:-$BASE_DIR/tmp}"  # Temporary data directory
LOGS_DIR="${LOGS_DIR:-$BASE_DIR/logs}"  # Logs directory
ARCHIVES_DIR="${ARCHIVES_DIR:-$BASE_DIR/archives}"  # Archives directory

# ==== Webserver (NGINX) ====
NGINX_PROXY_DIR="${NGINX_PROXY_DIR:-$BASE_DIR/webserver/nginx}"  # NGINX proxy directory
PROXY_CONF_DIR="${PROXY_CONF_DIR:-$NGINX_PROXY_DIR/conf.d}"  # NGINX configuration directory
NGINX_SCRIPTS_DIR="${NGINX_SCRIPTS_DIR:-$NGINX_PROXY_DIR/scripts}"  # NGINX scripts directory
SSL_DIR="${SSL_DIR:-$NGINX_PROXY_DIR/ssl}"  # SSL directory for NGINX
NGINX_MAIN_CONF="${NGINX_MAIN_CONF:-$NGINX_PROXY_DIR/globals/nginx.conf}"  # NGINX main configuration file

# ==== Utility scripts ====
SETUP_WORDPRESS_SCRIPT="${SETUP_WORDPRESS_SCRIPT:-$WP_SCRIPTS_DIR/wp-setup.sh}"  # WordPress setup script
PHP_USER="${PHP_USER:-nobody}"  # PHP user
PHP_CONTAINER_WP_PATH="${PHP_CONTAINER_WP_PATH:-/var/www/html}"  # PHP container WordPress path
# ==== Network & container configuration ====
DOCKER_NETWORK="${DOCKER_NETWORK:-proxy_network}"  # Docker network name
NGINX_PROXY_CONTAINER="${NGINX_PROXY_CONTAINER:-nginx-proxy}"  # NGINX proxy container name

# ==== Terminal colors ====
RED="${RED:-\033[1;31m}"  # Red
GREEN="${GREEN:-\033[1;32m}"  # Green
YELLOW="${YELLOW:-\033[1;33m}"  # Yellow
BLUE="${BLUE:-\033[1;34m}"  # Blue
MAGENTA="${MAGENTA:-\033[1;35m}"  # Magenta
CYAN="${CYAN:-\033[1;36m}"  # Cyan
WHITE="${WHITE:-\033[1;37m}"  # White
NC="${NC:-\033[0m}"  # No color

# ==== Emoji 🫠 ====
CHECKMARK="${GREEN}✅${NC}"
CROSSMARK="${RED}❌${NC}"

# ==== Rclone configuration ====
RCLONE_CONFIG_DIR="${RCLONE_CONFIG_DIR:-$BASE_DIR/shared/config/rclone}"  # Rclone config directory
RCLONE_CONFIG_FILE="${RCLONE_CONFIG_FILE:-$RCLONE_CONFIG_DIR/rclone.conf}"  # Rclone config file

# ==== Import utility functions ====
source "${FUNCTIONS_DIR}/utils/system_utils.sh"  # System utilities
source "${FUNCTIONS_DIR}/utils/docker_utils.sh"  # Docker utilities
source "${FUNCTIONS_DIR}/utils/file_utils.sh"  # File utilities
source "${FUNCTIONS_DIR}/utils/network_utils.sh"  # Network utilities
source "${FUNCTIONS_DIR}/utils/ssl_utils.sh"  # SSL utilities
source "${FUNCTIONS_DIR}/utils/wp_utils.sh"  # WordPress utilities
source "${FUNCTIONS_DIR}/utils//php_utils.sh"  # PHP utilities
source "${FUNCTIONS_DIR}/utils/db_utils.sh"  # Database utilities
source "${FUNCTIONS_DIR}/utils/website_utils.sh"  # Website utilities
source "${FUNCTIONS_DIR}/utils/misc_utils.sh"  # Miscellaneous utilities
source "${FUNCTIONS_DIR}/utils/nginx_utils.sh"  # NGINX utilities
