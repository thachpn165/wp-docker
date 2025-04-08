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

source "$FUNCTIONS_DIR/utils/wp_utils.sh"
source "$FUNCTIONS_DIR/website/website_check_and_up.sh"
source "$FUNCTIONS_DIR/setup-aliases.sh"
source "$FUNCTIONS_DIR/utils/env_utils.sh"

# === Ensure CORE_CHANNEL is set in .env ===
if [[ ! -f "$CORE_ENV" ]]; then
  echo -e "$WARNING_ENV_NOT_FOUND"
  touch "$CORE_ENV"
fi

# === Prompt language selection if LANG_CODE is not set ===
if ! grep -q "^LANG_CODE=" "$CORE_ENV"; then
  echo -e "\n🌐 Please select a language:"
  options=("English (en)" "Vietnamese (vi)")
  PS3="Select a language number: "
  select opt in "${options[@]}"; do
    case $REPLY in
      1)
        lang_code="en"
        break
        ;;
      2)
        lang_code="vi"
        break
        ;;
      *)
        echo "❌ Invalid selection. Please try again."
        ;;
    esac
  done

  echo "✅ Language selected: $lang_code"
  echo "LANG_CODE=\"$lang_code\"" >> "$CORE_ENV"
fi

# =============================================
# 🔧 Khởi tạo file cấu hình .config.json
# Hàm core_init_config sẽ hỏi để thiết lập channel, ngôn ngữ,...
# Lưu tại: $BASE_DIR/.config.json
# =============================================
core_init_config

clear
setup_timezone
check_and_add_alias

if ! command -v docker &> /dev/null; then
  install_docker
else
  echo -e "$SUCCESS_DOCKER_INSTALLED"
fi

if ! docker compose version &> /dev/null; then
  install_docker_compose
else
  echo -e "$SUCCESS_DOCKER_COMPOSE_INSTALLED"
fi

if ! crontab -l | grep -q "$CLI_DIR/php_get_version.sh"; then
  echo "0 2 * * * bash $CLI_DIR/php_get_version.sh" | crontab -
  echo -e "$SUCCESS_CRON_PHP_VERSION_SET"
else
  echo -e "$WARNING_CRON_PHP_VERSION_EXISTS"
fi

start_docker_if_needed
check_docker_group

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

pushd "$NGINX_PROXY_DIR" > /dev/null

if ! docker compose ps | grep -q "nginx-proxy.*Up"; then
  echo -e "$INFO_NGINX_PROXY_STARTING"
  docker compose up -d || exit_if_error 1 "$ERROR_NGINX_PROXY_START_FAILED"
fi

echo -e "$INFO_NGINX_PROXY_WAIT"
for i in {1..10}; do
  status=$(docker inspect -f "{{.State.Status}}" nginx-proxy 2>/dev/null)
  if [[ "$status" == "running" ]]; then
    echo -e "$SUCCESS_NGINX_PROXY_RUNNING"
    break
  fi
  sleep 1
done

if [[ "$status" != "running" ]]; then
  echo -e "$ERROR_NGINX_PROXY_NOT_RUNNING"
  docker logs nginx-proxy 2>&1 | tail -n 30
  echo -e "$ERROR_NGINX_PROXY_LOG_HINT"
  exit 1
fi

popd > /dev/null

create_docker_network "$DOCKER_NETWORK"
website_check_and_up

check_required_commands

echo -e "BASE_DIR: $BASE_DIR"
echo -e "LOGS_DIR: $LOGS_DIR"

echo -e "$SUCCESS_SYSTEM_READY"
