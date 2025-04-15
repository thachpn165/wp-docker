#!/usr/bin/env bash
#shellcheck disable=SC2034
# Kiểm tra nếu đã được load
if [[ "${LOADED_CONFIG_FILE:-}" == "true" ]]; then
  # Đã load rồi, thoát ngay
  return 0
fi

# Đánh dấu là đã load
LOADED_CONFIG_FILE=true
#=============================================
# ⚙️ WP Docker - GLOBAL CONFIGURATION (config.sh)
# =============================================

# ==== 1. Determine BASE_DIR ====
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
CONFIG_DIR="$(dirname "$SCRIPT_PATH")"

if [[ "$CONFIG_DIR" == */src/shared/config ]]; then
  BASE_DIR="$(cd "$CONFIG_DIR/../../.." && pwd)/src"
  DEV_MODE=true
else
  BASE_DIR="$(cd "$CONFIG_DIR/../.." && pwd)"

  DEV_MODE=false
fi
PROJECT_DIR=$BASE_DIR
DEBUG_MODE="false"
JSON_CONFIG_FILE="$BASE_DIR/.config.json"

safe_source "$BASE_DIR/shared/scripts/functions/utils/json_utils.sh"

# ==== 4. Load log/debug helpers ====
safe_source "$BASE_DIR/shared/scripts/functions/utils/log_utils.sh"

# ==== 3. Load i18n language file ====
safe_source "$BASE_DIR/shared/lang/lang_loader.sh"

# ==== 5. Define core system variables ====
LANG_LIST=("vi" "en")
OFFICIAL_REPO_TAG="latest"
NIGHTLY_REPO_TAG="nightly"

INSTALL_DIR="${INSTALL_DIR:-/opt/wp-docker}"
CORE_DIR="${CORE_DIR:-$BASE_DIR/shared/core}"
CORE_LIB_DIR="${CORE_FUNCTIIONS_DIR:-$CORE_DIR/lib}"
MYSQL_DIR="$CORE_DIR/mysql"
TMP_DIR="${TMP_DIR:-$BASE_DIR/tmp}"
LOGS_DIR="${LOGS_DIR:-$BASE_DIR/logs}"
DEBUG_LOG="${DEBUG_LOG:-$LOGS_DIR/debug.log}"
ARCHIVES_DIR="${ARCHIVES_DIR:-$BASE_DIR/archives}"
REPO_URL="${REPO_URL:-https://github.com/thachpn165/wp-docker}"
REPO_NAME="${REPO_NAME:-wp-docker}"
ZIP_NAME="${ZIP_NAME:-wp-docker.zip}"
CORE_VERSION_FILE="${CORE_VERSION_FILE:-version.txt}"
CORE_CURRENT_VERSION="${CORE_CURRENT_VERSION:-$BASE_DIR/$CORE_VERSION_FILE}"
CORE_TEMPLATE_VERSION_FILE="${CORE_TEMPLATE_VERSION_FILE:-shared/templates/.template_version}"
LOG_FILE="${LOG_FILE:-/tmp/update_wp_docker.log}"
CORE_LATEST_VERSION="${CORE_LATEST_VERSION:-https://raw.githubusercontent.com/thachpn165/${REPO_NAME}/refs/heads/main/src/${CORE_VERSION_FILE}}"
CORE_NIGHTLY_VERSION="${CORE_NIGHTLY_VERSION:-https://raw.githubusercontent.com/thachpn165/wp-docker/refs/tags/nightly/src/version.txt}"
MYSQL_DIR="${CORE_MARIADB_DIR:-$BASE_DIR/shared/core/mysql}"
MYSQL_IMAGE="${MYSQL_IMAGE:-mariadb:10.11}"
MYSQL_CONTAINER_NAME="wpdocker-mariadb"
MYSQL_VOLUME_NAME="wpdocker-mariadb-data"
MYSQL_CONFIG_FILE="$MYSQL_DIR/mysql.cnf"
# ==== 6. Define directory structure ====
SITES_DIR="${SITES_DIR:-$BASE_DIR/sites}"
TEMPLATES_DIR="${TEMPLATES_DIR:-$BASE_DIR/shared/templates}"
CONFIG_DIR="${CONFIG_DIR:-$BASE_DIR/shared/config}"
SCRIPTS_DIR="${SCRIPTS_DIR:-$BASE_DIR/shared/scripts}"
CLI_DIR="${CLI_DIR:-$SCRIPTS_DIR/cli}"
MENU_DIR="${MENU_DIR:-$SCRIPTS_DIR/menu}"
FUNCTIONS_DIR="${FUNCTIONS_DIR:-$SCRIPTS_DIR/functions}"
WP_SCRIPTS_DIR="${WP_SCRIPTS_DIR:-$SCRIPTS_DIR/wp-scripts}"
WEBSITE_MGMT_DIR="${WEBSITE_MGMT_DIR:-$SCRIPTS_DIR/website-management}"
SYSTEM_TOOLS_FUNC_DIR="${SYSTEM_TOOLS_FUNC_DIR:-$FUNCTIONS_DIR/system-tools}"
SCRIPTS_FUNCTIONS_DIR="${SCRIPTS_FUNCTIONS_DIR:-$FUNCTIONS_DIR}"

# ==== 7. Webserver (NGINX) ====
PHP_CONTAINER_SUFFIX="${PHP_CONTAINER_SUFFIX:--php}"
DB_CONTAINER_SUFFIX="${DB_CONTAINER_SUFFIX:--mariadb}"
DB_VOLUME_SUFFIX="_mariadb_data"
NGINX_PROXY_DIR="$CORE_DIR/webserver/nginx"
PROXY_CONF_DIR="${PROXY_CONF_DIR:-$NGINX_PROXY_DIR/conf.d}"
NGINX_SCRIPTS_DIR="${NGINX_SCRIPTS_DIR:-$NGINX_PROXY_DIR/scripts}"
SSL_DIR="${SSL_DIR:-$NGINX_PROXY_DIR/ssl}"
NGINX_MAIN_CONF="${NGINX_MAIN_CONF:-$NGINX_PROXY_DIR/globals/nginx.conf}"

# ==== 8. Rclone configuration ====
RCLONE_CONFIG_DIR="${RCLONE_CONFIG_DIR:-$BASE_DIR/shared/config/rclone}"
RCLONE_CONFIG_FILE="${RCLONE_CONFIG_FILE:-$RCLONE_CONFIG_DIR/rclone.conf}"

# ==== 9. Docker/network ====
DOCKER_NETWORK="${DOCKER_NETWORK:-proxy_network}"
NGINX_PROXY_CONTAINER="${NGINX_PROXY_CONTAINER:-nginx-proxy}"
PHP_USER="${PHP_USER:-nobody}"
PHP_CONTAINER_WP_PATH="${PHP_CONTAINER_WP_PATH:-/var/www/html}"

# ==== 10. Terminal colors ====
RED="${RED:-$'\033[1;31m'}"
GREEN="${GREEN:-$'\033[1;32m'}"
YELLOW="${YELLOW:-$'\033[1;33m'}"
BLUE="${BLUE:-$'\033[1;36m'}"
MAGENTA="${MAGENTA:-$'\033[1;35m'}"
CYAN="${CYAN:-$'\033[1;36m'}"
WHITE="${WHITE:-$'\033[1;37m'}"
STRONG="${STRONG:-$'\033[1m'}"
NC="${NC:-$'\033[0m'}"

# ==== 12. Template meta ====
export TEMPLATE_VERSION_FILE="${TEMPLATE_VERSION_FILE:-$BASE_DIR/shared/templates/.template_version}"
export TEMPLATE_CHANGELOG_FILE="${TEMPLATE_CHANGELOG_FILE:-$BASE_DIR/shared/templates/TEMPLATE_CHANGELOG.md}"

# ==== 13. Test mode ====
TEST_MODE="${TEST_MODE:-false}"
TEST_ALWAYS_READY="${TEST_ALWAYS_READY:-false}"

# ==== 14. Load utility functions ====
#Core functions
safe_source "$CORE_LIB_DIR/mysql_utils.sh" 

# Function utils
safe_source "$FUNCTIONS_DIR/utils/system_utils.sh"
safe_source "$FUNCTIONS_DIR/utils/docker_utils.sh"
safe_source "$FUNCTIONS_DIR/utils/file_utils.sh"
safe_source "$FUNCTIONS_DIR/utils/network_utils.sh"
safe_source "$FUNCTIONS_DIR/utils/wp_utils.sh"
safe_source "$FUNCTIONS_DIR/utils/php_utils.sh"
safe_source "$FUNCTIONS_DIR/utils/website_utils.sh"
safe_source "$FUNCTIONS_DIR/utils/misc_utils.sh"
safe_source "$FUNCTIONS_DIR/utils/nginx_utils.sh"
safe_source "$FUNCTIONS_DIR/utils/cli_params.sh"
safe_source "$FUNCTIONS_DIR/core/core_state_utils.sh"


