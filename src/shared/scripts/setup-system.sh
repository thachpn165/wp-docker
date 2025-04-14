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
if ! command -v docker &>/dev/null; then
  install_docker
else
  echo -e "$SUCCESS_DOCKER_INSTALLED"
fi

if ! docker compose version &>/dev/null; then
  install_docker_compose
else
  echo -e "$SUCCESS_DOCKER_COMPOSE_INSTALLED"
fi

# =============================================
# 🔁 Setup CRON for PHP version refresh
# =============================================
if ! crontab -l | grep -q "$CLI_DIR/php_get_version.sh"; then
  echo "0 2 * * * bash $CLI_DIR/php_get_version.sh" | crontab -
  echo -e "$SUCCESS_CRON_PHP_VERSION_SET"
else
  echo -e "$WARNING_CRON_PHP_VERSION_EXISTS"
fi

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
# 🌐 Start NGINX Proxy if not running
# =============================================
if ! docker compose -f "$NGINX_PROXY_DIR/docker-compose.yml" ps | grep -q "$NGINX_PROXY_CONTAINER.*Up"; then
  echo -e "$INFO_NGINX_PROXY_STARTING"
  docker compose -f "$NGINX_PROXY_DIR/docker-compose.yml" up -d || exit_if_error 1 "$ERROR_NGINX_PROXY_START_FAILED"
fi

echo -e "$INFO_NGINX_PROXY_WAIT"
for _ in {1..10}; do
  status=$(docker inspect -f "{{.State.Status}}" "$NGINX_PROXY_CONTAINER" 2>/dev/null)
  if [[ "$status" == "running" ]]; then
    echo -e "$SUCCESS_NGINX_PROXY_RUNNING"
    break
  fi
  sleep 1
done

if [[ "$status" != "running" ]]; then
  echo -e "$ERROR_NGINX_PROXY_NOT_RUNNING"
  docker logs "$NGINX_PROXY_CONTAINER" 2>&1 | tail -n 30
  echo -e "$ERROR_NGINX_PROXY_LOG_HINT"
  exit 1
fi
# =============================================
# ✅ Verify required commands are available
# =============================================
check_required_commands

# =============================================
# Start MySQL if not running
# =============================================
core_mysql_start

# =============================================
# 🕸 Create Docker network if missing
# =============================================
create_docker_network "$DOCKER_NETWORK"


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
echo -e "$SUCCESS_SYSTEM_READY"