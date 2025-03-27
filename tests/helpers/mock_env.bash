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
  export ZIP_NAME="mock-wp-docker.zip"
  export TMP_DIR="$BASE_DIR/tmp"
  export LOG_FILE="$BASE_DIR/update.log"
  export REPO_URL="https://example.com"
  export DEV_MODE=true
  export PHP_USER="nobody"
  export DOCKER_NETWORK="proxy_network"
  export NGINX_PROXY_CONTAINER="nginx-proxy"

  RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' CYAN='' WHITE='' NC=''

  export RCLONE_CONFIG_DIR="$CONFIG_DIR/rclone"
  export RCLONE_CONFIG_FILE="$RCLONE_CONFIG_DIR/rclone.conf"
mkdir -p "$FUNCTIONS_DIR" "$FUNCTIONS_DIR/php"
mkdir -p "$FUNCTIONS_DIR/core"
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
cp "$BATS_TEST_DIRNAME/../../src/shared/scripts/functions/nginx/nginx_utils.sh"          "$FUNCTIONS_DIR/"
cp "$BATS_TEST_DIRNAME/../../src/shared/scripts/functions/core/core_update.sh" \
   "$FUNCTIONS_DIR/core/"
cp "$BATS_TEST_DIRNAME/../../src/shared/scripts/functions/core/core_version_management.sh" \
   "$FUNCTIONS_DIR/core/"


# Tạo file config.sh giả tại đúng vị trí mà core_update.sh cần
mkdir -p "$PROJECT_DIR/shared/config"
cat > "$PROJECT_DIR/shared/config/config.sh" <<'EOF'
# ========== Fake config.sh for test ==========

BASE_DIR="${BASE_DIR:-$PROJECT_DIR}"
INSTALL_DIR="${INSTALL_DIR:-$BASE_DIR}"
TMP_DIR="${TMP_DIR:-$BASE_DIR/tmp}"
REPO_URL="${REPO_URL:-https://example.com}"
ZIP_NAME="${ZIP_NAME:-wp-docker.zip}"
LOG_FILE="${LOG_FILE:-$BASE_DIR/update.log}"
CORE_VERSION_FILE="${CORE_VERSION_FILE:-version.txt}"
CORE_LATEST_VERSION="${CORE_LATEST_VERSION:-file://$BASE_DIR/latest_version.txt}"

SITES_DIR="${SITES_DIR:-$BASE_DIR/sites}"
TEMPLATES_DIR="${TEMPLATES_DIR:-$BASE_DIR/shared/templates}"
CONFIG_DIR="${CONFIG_DIR:-$BASE_DIR/shared/config}"
SCRIPTS_DIR="${SCRIPTS_DIR:-$BASE_DIR/shared/scripts}"
FUNCTIONS_DIR="${FUNCTIONS_DIR:-$SCRIPTS_DIR/functions}"
SCRIPTS_FUNCTIONS_DIR="${SCRIPTS_FUNCTIONS_DIR:-$FUNCTIONS_DIR}"

RCLONE_CONFIG_DIR="${RCLONE_CONFIG_DIR:-$CONFIG_DIR/rclone}"
RCLONE_CONFIG_FILE="${RCLONE_CONFIG_FILE:-$RCLONE_CONFIG_DIR/rclone.conf}"

PHP_USER="nobody"
DOCKER_NETWORK="proxy_network"
NGINX_PROXY_CONTAINER="nginx-proxy"

RED="" GREEN="" YELLOW="" BLUE="" MAGENTA="" CYAN="" WHITE="" NC=""
CHECKMARK="✅"
CROSSMARK="❌"

# Avoid sourcing actual functions again during tests
EOF

}
