#!/bin/bash

# ========================================
# ⚙️ setup-system.sh – Initialize WP Docker system
# ========================================

# === Load config.sh from anywhere using universal loader ===
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
  if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
    source "$SCRIPT_PATH/shared/config/load_config.sh"
    break
  fi
  SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done

# === Load necessary functions ===
safe_source "$CORE_LIB_DIR/mysql_init.sh"
safe_source "$FUNCTIONS_DIR/utils/wp_utils.sh"
safe_source "$FUNCTIONS_DIR/website/website_check_and_up.sh"
safe_source "$FUNCTIONS_DIR/setup-aliases.sh"

# =============================================
# 🔧 Initialize config (.config.json with language, channel,...)
# =============================================
core_init_config

clear
setup_timezone
check_and_add_alias

# =============================================
# ⚙️ Check & install Docker and Docker Compose
# =============================================

install_docker

# ==============================================
# cron_loader.sh
# ==============================================
# Check if the cron job is already set
cron_register_loader_if_needed

# =============================================
# 🐳 Start Docker if not running & check group
# =============================================
start_docker_if_needed
check_docker_group

# =============================================
# ⚡ Install WP-CLI if missing
# =============================================
WP_CLI_PATH="$BASE_DIR/shared/bin/wp"
if [[ ! -f "$WP_CLI_PATH" ]]; then
  echo -e "$WARNING_WPCLI_NOT_FOUND"
  curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar || exit_if_error 1 "$ERROR_WPCLI_DOWNLOAD_FAILED"
  chmod +x wp-cli.phar
  mv wp-cli.phar "$WP_CLI_PATH" || exit_if_error 1 "$ERROR_WPCLI_MOVE_FAILED"
  echo -e "$SUCCESS_WPCLI_INSTALLED"
else
  echo -e "$(printf "$SUCCESS_WPCLI_EXISTS" "$WP_CLI_PATH")"
fi

# =============================================
# ✅ Verify required commands are available
# =============================================
check_required_commands

# =============================================
# 🕸 Create Docker network if missing
# =============================================
create_docker_network "$DOCKER_NETWORK"

# =============================================
# Check docker volumes and create if missing
# =============================================
docker_volume_check_fastcgicache

# =============================================
# Start MySQL if not running
# =============================================
core_mysql_start

# =============================================
# Start Redis if not running
# =============================================
redis_start
# =============================================
# 🚀 Start all existing websites
# =============================================
# TODO: Improve by checking both folder and .config.json
website_check_and_up

# =============================================
# Check logs directory and create if missing
# =============================================
if [[ ! -d "$LOGS_DIR" ]]; then
  mkdir -p "$LOGS_DIR" || exit_if_error 1 "$ERROR_LOGS_DIR_CREATE_FAILED"
  echo -e "$(printf "$SUCCESS_LOGS_DIR_CREATED" "$LOGS_DIR")"
else
  echo -e "$(printf "$SUCCESS_LOGS_DIR_EXISTS" "$LOGS_DIR")"
fi
# =============================================
# 🎉 System ready
# =============================================
# =============================================
# 🌐 Start NGINX Proxy if not running
# =============================================
nginx_init
wait_for_nginx_container || exit 1
echo -e "$SUCCESS_SYSTEM_READY"