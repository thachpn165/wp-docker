# tests/helpers/mock_env.bash

setup_env() {
  export TEST_SANDBOX_DIR="/tmp/wp-docker-test-$$"
  mkdir -p "$TEST_SANDBOX_DIR"

  export BASE_DIR="$TEST_SANDBOX_DIR"
  export PROJECT_DIR="$BASE_DIR"  # ✅ Quan trọng để định vị đúng config.sh
  export CONFIG_DIR="$BASE_DIR/shared/config"
  export CONFIG_FILE="$CONFIG_DIR/config.sh"
  export FUNCTIONS_DIR="$BASE_DIR/shared/scripts/functions"
  export SCRIPTS_FUNCTIONS_DIR="$FUNCTIONS_DIR"
  export SITES_DIR="$BASE_DIR/sites"
  export TEMPLATES_DIR="$BASE_DIR/shared/templates"
  export LOGS_DIR="$BASE_DIR/logs"
  export SSL_DIR="$BASE_DIR/nginx-proxy/ssl"
  export TMP_DIR="$BASE_DIR/tmp"

  export DEV_MODE=true
  export PHP_USER="nobody"
  export DOCKER_NETWORK="proxy_network"
  export NGINX_PROXY_CONTAINER="nginx-proxy"

  RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' CYAN='' WHITE='' NC=''

  export RCLONE_CONFIG_DIR="$CONFIG_DIR/rclone"
  export RCLONE_CONFIG_FILE="$RCLONE_CONFIG_DIR/rclone.conf"
mkdir -p "$FUNCTIONS_DIR" "$FUNCTIONS_DIR/php"
cp "$BATS_TEST_DIRNAME/../../src/shared/scripts/functions/system_utils.sh"         "$FUNCTIONS_DIR/"
cp "$BATS_TEST_DIRNAME/../../src/shared/scripts/functions/docker_utils.sh"         "$FUNCTIONS_DIR/"
cp "$BATS_TEST_DIRNAME/../../src/shared/scripts/functions/file_utils.sh"           "$FUNCTIONS_DIR/"
cp "$BATS_TEST_DIRNAME/../../src/shared/scripts/functions/network_utils.sh"        "$FUNCTIONS_DIR/"
cp "$BATS_TEST_DIRNAME/../../src/shared/scripts/functions/ssl_utils.sh"            "$FUNCTIONS_DIR/"
cp "$BATS_TEST_DIRNAME/../../src/shared/scripts/functions/wp_utils.sh"             "$FUNCTIONS_DIR/"
cp "$BATS_TEST_DIRNAME/../../src/shared/scripts/functions/php/php_utils.sh"        "$FUNCTIONS_DIR/php/"
cp "$BATS_TEST_DIRNAME/../../src/shared/scripts/functions/db_utils.sh"             "$FUNCTIONS_DIR/"
cp "$BATS_TEST_DIRNAME/../../src/shared/scripts/functions/website_utils.sh"        "$FUNCTIONS_DIR/"
cp "$BATS_TEST_DIRNAME/../../src/shared/scripts/functions/misc_utils.sh"           "$FUNCTIONS_DIR/"
cp "$BATS_TEST_DIRNAME/../../src/shared/scripts/functions/nginx_utils.sh"          "$FUNCTIONS_DIR/"

}
