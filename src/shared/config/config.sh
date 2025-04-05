#!/usr/bin/env bash

# =============================================
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

# ==== 2. Load .env file ====
CORE_ENV="${CORE_ENV:-$BASE_DIR/.env}"

# Load env loader first
source "$BASE_DIR/shared/scripts/functions/utils/env_utils.sh"

# Load environment variables
env_load "$CORE_ENV"

# Fallback values
LANG_CODE="${LANG_CODE:-vi}"
DEBUG_MODE="${DEBUG_MODE:-false}"
DEV_MODE="${DEV_MODE:-$DEV_MODE}"

# ==== 3. Load i18n language file ====
source "$BASE_DIR/shared/lang/lang_loader.sh"

# ==== 4. Load log/debug helpers ====
source "$BASE_DIR/shared/scripts/functions/utils/log_utils.sh"

# ==== 5. Define core system variables ====
INSTALL_DIR="${INSTALL_DIR:-/opt/wp-docker}"
TMP_DIR="${TMP_DIR:-$BASE_DIR/tmp}"
LOGS_DIR="${LOGS_DIR:-$BASE_DIR/logs}"
ARCHIVES_DIR="${ARCHIVES_DIR:-$BASE_DIR/archives}"
REPO_URL="${REPO_URL:-https://github.com/thachpn165/wp-docker}"
REPO_NAME="${REPO_NAME:-wp-docker}"
ZIP_NAME="${ZIP_NAME:-wp-docker.zip}"
CORE_VERSION_FILE="${CORE_VERSION_FILE:-version.txt}"
CORE_TEMPLATE_VERSION_FILE="${CORE_TEMPLATE_VERSION_FILE:-shared/templates/.template_version}"
LOG_FILE="${LOG_FILE:-/tmp/update_wp_docker.log}"
CORE_LATEST_VERSION="${CORE_LATEST_VERSION:-https://raw.githubusercontent.com/thachpn165/${REPO_NAME}/refs/heads/main/src/${CORE_VERSION_FILE}}"
CORE_NIGHTLY_VERSION="${CORE_NIGHTLY_VERSION:-https://raw.githubusercontent.com/thachpn165/${REPO_NAME}/refs/heads/nightly/src/${CORE_VERSION_FILE}}"

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
NGINX_PROXY_DIR="${NGINX_PROXY_DIR:-$BASE_DIR/webserver/nginx}"
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
BLUE="${BLUE:-$'\033[1;34m'}"
MAGENTA="${MAGENTA:-$'\033[1;35m'}"
CYAN="${CYAN:-$'\033[1;36m'}"
WHITE="${WHITE:-$'\033[1;37m'}"
NC="${NC:-$'\033[0m'}"

# ==== 11. Emoji symbols ====
CHECKMARK="${GREEN}✅ ${NC}"
CROSSMARK="${RED}❌ ${NC}"
SAVE="${WHITE}💾 ${NC}"
WARNING="${YELLOW}⚠️ ${NC}"
INFO="${WHITE}ℹ️ ${NC}"
ERROR="${RED}❗ ${NC}"
IMPORTANT="${RED}🚨 ${NC}"

# ==== 12. Template meta ====
export TEMPLATE_VERSION_FILE="${TEMPLATE_VERSION_FILE:-$BASE_DIR/shared/templates/.template_version}"
export TEMPLATE_CHANGELOG_FILE="${TEMPLATE_CHANGELOG_FILE:-$BASE_DIR/shared/templates/TEMPLATE_CHANGELOG.md}"

# ==== 13. Test mode ====
TEST_MODE="${TEST_MODE:-false}"
TEST_ALWAYS_READY="${TEST_ALWAYS_READY:-false}"

# ==== 14. Load utility functions ====
source "$FUNCTIONS_DIR/utils/system_utils.sh"
source "$FUNCTIONS_DIR/utils/docker_utils.sh"
source "$FUNCTIONS_DIR/utils/file_utils.sh"
source "$FUNCTIONS_DIR/utils/network_utils.sh"
source "$FUNCTIONS_DIR/utils/ssl_utils.sh"
source "$FUNCTIONS_DIR/utils/wp_utils.sh"
source "$FUNCTIONS_DIR/utils/php_utils.sh"
source "$FUNCTIONS_DIR/utils/db_utils.sh"
source "$FUNCTIONS_DIR/utils/website_utils.sh"
source "$FUNCTIONS_DIR/utils/misc_utils.sh"
source "$FUNCTIONS_DIR/utils/nginx_utils.sh"
