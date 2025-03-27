# tests/helpers/mock_env.bash

setup_env() {
  export TEST_SANDBOX_DIR="/tmp/wp-docker-test-$$"
  mkdir -p "$TEST_SANDBOX_DIR"

  export BASE_DIR="$TEST_SANDBOX_DIR"
  export CONFIG_FILE="$BASE_DIR/shared/config/config.sh"
  export CONFIG_DIR="$BASE_DIR/shared/config"
  export FUNCTIONS_DIR="$BASE_DIR/shared/scripts/functions"
  export SCRIPTS_FUNCTIONS_DIR="$FUNCTIONS_DIR"
  export SITES_DIR="$BASE_DIR/sites"
  export TEMPLATES_DIR="$BASE_DIR/shared/templates"
  export LOGS_DIR="$BASE_DIR/logs"
  export SSL_DIR="$BASE_DIR/nginx-proxy/ssl"
  export TMP_DIR="$BASE_DIR/tmp"

  export DEV_MODE=true
  export DOCKER_NETWORK="proxy_network"
  export NGINX_PROXY_CONTAINER="nginx-proxy"
  export PHP_USER="nobody"

  RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' CYAN='' WHITE='' NC=''

  export RCLONE_CONFIG_DIR="$CONFIG_DIR/rclone"
  export RCLONE_CONFIG_FILE="$RCLONE_CONFIG_DIR/rclone.conf"
}
