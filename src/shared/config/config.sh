#!/usr/bin/env bash
#shellcheck disable=SC2034

# Prevent re-loading
[[ "${LOADED_CONFIG_FILE:-}" == "true" ]] && return 0
LOADED_CONFIG_FILE=true

# =============================================
# ⚙️ WP Docker - GLOBAL CONFIGURATION (config.sh)
# =============================================

# ==== 1. Detect BASE_DIR & PROJECT_DIR ====
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
CONFIG_DIR="$(dirname "$SCRIPT_PATH")"

if [[ "$CONFIG_DIR" == */src/shared/config ]]; then
  BASE_DIR="$(cd "$CONFIG_DIR/../../.." && pwd)/src"
  DEV_MODE=true
else
  BASE_DIR="$(cd "$CONFIG_DIR/../.." && pwd)"
  DEV_MODE=false
fi
PROJECT_DIR="$BASE_DIR"

DEBUG_MODE="false"
JSON_CONFIG_FILE="$BASE_DIR/.config.json"

# ==== 2. Load core libs and i18n ====
safe_source "$BASE_DIR/shared/core/lib/json_utils.sh"
safe_source "$BASE_DIR/shared/core/lib/log_utils.sh"
safe_source "$BASE_DIR/shared/lang/lang_loader.sh"

# ==== 3. Language ====
LANG_LIST=("vi" "en")

# ==== 4. Repository info ====
REPO_URL="https://github.com/thachpn165/wp-docker"
REPO_NAME="wp-docker"
ZIP_NAME="wp-docker.zip"
OFFICIAL_REPO_TAG="latest"
NIGHTLY_REPO_TAG="nightly"

# ==== 5. Version info ====
CORE_VERSION_FILE="version.txt"
CORE_CURRENT_VERSION="$BASE_DIR/$CORE_VERSION_FILE"
CORE_TEMPLATE_VERSION_FILE="shared/templates/.template_version"
CORE_LATEST_VERSION="https://raw.githubusercontent.com/thachpn165/${REPO_NAME}/refs/heads/main/src/${CORE_VERSION_FILE}"
CORE_NIGHTLY_VERSION="https://raw.githubusercontent.com/thachpn165/${REPO_NAME}/refs/tags/nightly/src/version.txt"

# ==== 6. Directory structure ====
INSTALL_DIR="/opt/wp-docker"
CORE_DIR="$BASE_DIR/shared/core"
CORE_LIB_DIR="$CORE_DIR/lib"
MYSQL_DIR="$CORE_DIR/mysql"
LOGS_DIR="$BASE_DIR/logs"
TMP_DIR="$BASE_DIR/tmp"
ARCHIVES_DIR="$BASE_DIR/archives"
SITES_DIR="$BASE_DIR/sites"
TEMPLATES_DIR="$BASE_DIR/shared/templates"
CONFIG_DIR="$BASE_DIR/shared/config"
SCRIPTS_DIR="$BASE_DIR/shared/scripts"
CLI_DIR="$SCRIPTS_DIR/cli"
MENU_DIR="$SCRIPTS_DIR/menu"
FUNCTIONS_DIR="$SCRIPTS_DIR/functions"
WP_SCRIPTS_DIR="$SCRIPTS_DIR/wp-scripts"
WEBSITE_MGMT_DIR="$SCRIPTS_DIR/website-management"
SYSTEM_TOOLS_FUNC_DIR="$FUNCTIONS_DIR/system-tools"
SCRIPTS_FUNCTIONS_DIR="$FUNCTIONS_DIR"
DEBUG_LOG="${DEBUG_LOG:-$LOGS_DIR/debug.log}"
# ==== 7. MySQL / Database ====
MYSQL_IMAGE="mariadb:10.11"
MYSQL_CONTAINER_NAME="wpdocker-mariadb"
MYSQL_VOLUME_NAME="wpdocker-mariadb-data"
MYSQL_CONFIG_FILE="$MYSQL_DIR/mysql.cnf"

# ==== 8. Redis ====
REDIS_CONTAINER="wpdocker-redis"

# ==== 9. Webserver (NGINX) ====
NGINX_PROXY_CONTAINER="nginx-proxy"
PHP_CONTAINER_SUFFIX="-php"
DB_CONTAINER_SUFFIX="-mariadb"
DB_VOLUME_SUFFIX="_mariadb_data"
WEBSERVER_DIR="$CORE_DIR/webserver"
NGINX_PROXY_DIR="$WEBSERVER_DIR/nginx"
PROXY_CONF_DIR="$NGINX_PROXY_DIR/conf.d"
NGINX_SCRIPTS_DIR="$NGINX_PROXY_DIR/scripts"
SSL_DIR="$NGINX_PROXY_DIR/ssl"
NGINX_MAIN_CONF="$NGINX_PROXY_DIR/globals/nginx.conf"

# ==== 10. Rclone ====
RCLONE_CONFIG_DIR="$BASE_DIR/shared/config/rclone"
RCLONE_CONFIG_FILE="$RCLONE_CONFIG_DIR/rclone.conf"

# ==== 11. Docker/Network ====
DOCKER_NETWORK="wpdocker_network"
PHP_USER="nobody"
PHP_CONTAINER_WP_PATH="/var/www/html"

# ==== 12. Colors ====
RED=$'\033[1;31m'
GREEN=$'\033[1;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[1;36m'
MAGENTA=$'\033[1;35m'
CYAN=$'\033[1;36m'
WHITE=$'\033[1;37m'
STRONG=$'\033[1m'
NC=$'\033[0m'

# ==== 13. Template meta ====
export TEMPLATE_VERSION_FILE="$BASE_DIR/shared/templates/.template_version"
export TEMPLATE_CHANGELOG_FILE="$BASE_DIR/shared/templates/TEMPLATE_CHANGELOG.md"

# ==== 14. Test mode ====
TEST_MODE="false"
TEST_ALWAYS_READY="false"

# ==== 15. Load all helper utils ====
safe_source "$CORE_LIB_DIR/mysql_utils.sh"
safe_source "$CORE_LIB_DIR/nginx_utils.sh"
safe_source "$CORE_LIB_DIR/docker_utils.sh"
safe_source "$CORE_LIB_DIR/network_utils.sh"
safe_source "$CORE_LIB_DIR/system_utils.sh"
safe_source "$CORE_LIB_DIR/file_utils.sh"
safe_source "$CORE_LIB_DIR/misc_utils.sh"
safe_source "$CORE_LIB_DIR/redis_utils.sh"

safe_source "$FUNCTIONS_DIR/utils/wp_utils.sh"
safe_source "$FUNCTIONS_DIR/utils/php_utils.sh"
safe_source "$FUNCTIONS_DIR/utils/website_utils.sh"
safe_source "$FUNCTIONS_DIR/utils/cli_params.sh"
safe_source "$FUNCTIONS_DIR/core/core_state_utils.sh"
