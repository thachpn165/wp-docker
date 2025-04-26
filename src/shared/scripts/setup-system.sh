#!/bin/bash

# ========================================
# ⚙️ setup-system.sh – Initialize WP Docker system
# ========================================
# 
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
setup_timezone

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
wp_cli_install

# =============================================
# ✅ Verify required commands are available
# =============================================
core_system_check_required_commands

# =============================================
# 🕸 Create Docker network if missing
# =============================================
create_docker_network "$DOCKER_NETWORK" >/dev/null 2>&1

# =============================================
# Check docker volumes and create if missing
# =============================================
docker_volume_check_fastcgicache >/dev/null 2>&1

# =============================================
# Start MySQL if not running
# =============================================
core_mysql_start

# =============================================
# Start Redis if not running
# =============================================
redis_start

# =============================================
# Initialize $SITES_DIR
# =============================================
mkdir -p "$SITES_DIR" || exit_if_error 1 "$ERROR_SITES_DIR_CREATE_FAILED"
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
# Clean orphaned site config in NGINX
# =============================================
nginx_remove_orphaned_site_conf

# =============================================
# 🎉 System ready
# =============================================
# =============================================
# 🌐 Start NGINX Proxy if not running
# =============================================
nginx_init
wait_for_nginx_container || exit 1
check_and_add_alias
echo -e "$SUCCESS_SYSTEM_READY"