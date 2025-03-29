#!/usr/bin/env bash

# === Tạo sandbox môi trường test (thư mục tạm + cấu trúc) ===
create_test_sandbox() {
  export TEST_ID=$$
  export TEST_SANDBOX_DIR="/tmp/wp-docker-test-$TEST_ID"
  export BASE_DIR="$TEST_SANDBOX_DIR"
  export PROJECT_DIR="$BASE_DIR"
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
  export LOG_FILE="$BASE_DIR/update.log"
  export REPO_URL="https://example.com"
  export DEV_MODE=true
  export PHP_USER="nobody"
  export DOCKER_NETWORK="proxy_network"
  export NGINX_PROXY_CONTAINER="nginx-proxy"
  # ==== Webserver (NGINX) ====
  export NGINX_PROXY_DIR="${NGINX_PROXY_DIR:-$BASE_DIR/webserver/nginx}"  # NGINX proxy directory
  export PROXY_CONF_DIR="${PROXY_CONF_DIR:-$NGINX_PROXY_DIR/conf.d}"  # NGINX configuration directory
  export NGINX_SCRIPTS_DIR="${NGINX_SCRIPTS_DIR:-$NGINX_PROXY_DIR/scripts}"  # NGINX scripts directory
  export SSL_DIR="${SSL_DIR:-$NGINX_PROXY_DIR/ssl}"  # SSL directory for NGINX
  RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' CYAN='' WHITE='' NC=''

  export RCLONE_CONFIG_DIR="$CONFIG_DIR/rclone"
  export RCLONE_CONFIG_FILE="$RCLONE_CONFIG_DIR/rclone.conf"

  echo "[INFO] ✅ Creating test sandbox: $TEST_SANDBOX_DIR"
  mkdir -p "$FUNCTIONS_DIR"

  # Copy all logic từ repo source
  local PROJECT_ROOT="$(realpath "$BATS_TEST_DIRNAME/../..")"
  local REAL_SOURCE_DIR="$PROJECT_ROOT/src/shared/scripts/functions"

  cp "$REAL_SOURCE_DIR/"*.sh "$FUNCTIONS_DIR/" 2>/dev/null || true
  # Copy CLI wrapper scripts nếu có
  REAL_CLI_DIR="$PROJECT_ROOT/src/shared/scripts/cli"
  CLI_DIR="$BASE_DIR/shared/scripts/cli"
  mkdir -p "$CLI_DIR"
  cp "$REAL_CLI_DIR/"*.sh "$CLI_DIR/" 2>/dev/null || true

  for dir in backup-manager backup-scheduler core menu php nginx rclone setup-website ssl system-tools website; do
    mkdir -p "$FUNCTIONS_DIR/$dir"
    cp "$REAL_SOURCE_DIR/$dir/"*.sh "$FUNCTIONS_DIR/$dir/" 2>/dev/null || true
  done

  # Tạo config mock
  mkdir -p "$CONFIG_DIR"
  cp "$PROJECT_ROOT/src/shared/config/config.sh" "$CONFIG_FILE"

    # Append biến override cho sandbox vào cuối
cat >> "$CONFIG_FILE" <<EOF

# === Override for test sandbox ===
BASE_DIR="$BASE_DIR"
PROJECT_DIR="$BASE_DIR"
CONFIG_DIR="$CONFIG_DIR"
FUNCTIONS_DIR="$FUNCTIONS_DIR"
SCRIPTS_FUNCTIONS_DIR="$FUNCTIONS_DIR"
SITES_DIR="$SITES_DIR"
TEMPLATES_DIR="$TEMPLATES_DIR"
LOGS_DIR="$LOGS_DIR"
SSL_DIR="$SSL_DIR"
NGINX_PROXY_DIR="$NGINX_PROXY_DIR"
EOF



}

# === Xoá sandbox sau khi test xong ===
cleanup_test_sandbox() {
  echo "[INFO] 🧹 Cleaning test sandbox: $TEST_SANDBOX_DIR"
  [[ -n "$TEST_SANDBOX_DIR" && -d "$TEST_SANDBOX_DIR" ]] && rm -rf "$TEST_SANDBOX_DIR"
}
