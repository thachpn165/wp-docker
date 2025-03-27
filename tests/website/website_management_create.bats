#!/usr/bin/env bats

load '../helpers/mock_env.bash'

setup() {
  setup_env
  export TEST_ALWAYS_READY=true
  export PROJECT_DIR="$BASE_DIR"
  export TEST_MODE=true
  export TEST_DOMAIN="example.com"
  export TEST_SITE_NAME=""

  mkdir -p "$TEST_SANDBOX_DIR/bin"
  export PATH="$TEST_SANDBOX_DIR/bin:$PATH"

  # ==== Mock docker binary ====
  cat > "$TEST_SANDBOX_DIR/bin/docker" <<'EOF'
#!/bin/bash
echo "🧪 mock docker $@"
exit 0
EOF
  chmod +x "$TEST_SANDBOX_DIR/bin/docker"

  # ==== Tạo thư mục cần thiết ====
  mkdir -p \
    "$SITES_DIR" "$LOGS_DIR" "$TEMPLATES_DIR" "$CONFIG_DIR" \
    "$FUNCTIONS_DIR" "$FUNCTIONS_DIR/php" "$FUNCTIONS_DIR/website" \
    "$FUNCTIONS_DIR/nginx" "$FUNCTIONS_DIR/ssl" "$FUNCTIONS_DIR/db" \
    "$FUNCTIONS_DIR/system-tools" "$FUNCTIONS_DIR/wp" "$FUNCTIONS_DIR/mariadb_utils" \
    "$SCRIPTS_FUNCTIONS_DIR/setup-website"

  echo 'memory_limit = 256M' > "$TEMPLATES_DIR/php.ini.template"
  echo 'version: "3"' > "$TEMPLATES_DIR/docker-compose.yml.template"
  echo -e "8.3\n8.2\n8.1" > "$BASE_DIR/php_versions.txt"

  # ==== Copy các function thật vào ====
  cp "$BATS_TEST_DIRNAME/../../src/shared/scripts/functions/website/website_management_create.sh" "$FUNCTIONS_DIR/website/"
  cp "$BATS_TEST_DIRNAME/../../src/shared/scripts/functions/php/php_utils.sh" "$FUNCTIONS_DIR/php/" || true
  cp "$BATS_TEST_DIRNAME/../../src/shared/scripts/functions/file_utils.sh" "$FUNCTIONS_DIR/"
  cp "$BATS_TEST_DIRNAME/../../src/shared/scripts/functions/misc_utils.sh" "$FUNCTIONS_DIR/"
  cp "$BATS_TEST_DIRNAME/../../src/shared/scripts/functions/nginx/nginx_utils.sh" "$FUNCTIONS_DIR/nginx/"
  cp "$BATS_TEST_DIRNAME/../../src/shared/scripts/functions/ssl_utils.sh" "$FUNCTIONS_DIR/ssl/"
  cp "$BATS_TEST_DIRNAME/../../src/shared/scripts/functions/website/website_create_env.sh" "$FUNCTIONS_DIR/website/"
  cp "$BATS_TEST_DIRNAME/../../src/shared/scripts/functions/db_utils.sh" "$FUNCTIONS_DIR/db/" || true
  cp "$BATS_TEST_DIRNAME/../../src/shared/scripts/functions/system_utils.sh" "$FUNCTIONS_DIR/" || true

  # ==== Ghi đè lại php_choose_version để tránh treo khi test ====
  cat > "$FUNCTIONS_DIR/php/php_choose_version.sh" <<'EOF'
php_choose_version() {
  PHP_VERSIONS=("8.3" "8.2" "8.1")
  REPLY="8.3"
}
EOF

  # ==== Mock các script cài đặt ====
  echo 'echo "🧪 mock setup-nginx.sh"' > "$SCRIPTS_FUNCTIONS_DIR/setup-website/setup-nginx.sh"
  echo 'echo "🧪 mock setup-wordpress.sh $1"' > "$SCRIPTS_FUNCTIONS_DIR/setup-website/setup-wordpress.sh"
  chmod +x "$SCRIPTS_FUNCTIONS_DIR/setup-website/"*

  # ==== Tạo config.sh ====
  cat > "$CONFIG_FILE" <<EOF
#!/bin/bash
PROJECT_DIR="$PROJECT_DIR"
BASE_DIR="$BASE_DIR"
SITES_DIR="$SITES_DIR"
TEMPLATES_DIR="$TEMPLATES_DIR"
CONFIG_DIR="$CONFIG_DIR"
SCRIPTS_DIR="\$PROJECT_DIR/shared/scripts"
FUNCTIONS_DIR="\$SCRIPTS_DIR/functions"
SCRIPTS_FUNCTIONS_DIR="\$FUNCTIONS_DIR"
WP_SCRIPTS_DIR="\$SCRIPTS_DIR/wp-scripts"
WEBSITE_MGMT_DIR="\$SCRIPTS_DIR/website-management"
SYSTEM_TOOLS_FUNC_DIR="\$FUNCTIONS_DIR/system-tools"
TMP_DIR="\$PROJECT_DIR/tmp"
LOGS_DIR="\$PROJECT_DIR/logs"
ARCHIVES_DIR="\$PROJECT_DIR/archives"
SSL_DIR="\$PROJECT_DIR/nginx-proxy/ssl"

PHP_USER="nobody"
DOCKER_NETWORK="proxy_network"
NGINX_PROXY_CONTAINER="nginx-proxy"

RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' CYAN='' WHITE='' NC=''
RCLONE_CONFIG_DIR="\$CONFIG_DIR/rclone"
RCLONE_CONFIG_FILE="\$RCLONE_CONFIG_DIR/rclone.conf"

source "\$FUNCTIONS_DIR/misc_utils.sh"
EOF

  # ==== Source tất cả các hàm util và script chính ====
  source "$BATS_TEST_DIRNAME/../helpers/load_all_utils.sh"
  source "$FUNCTIONS_DIR/php/php_choose_version.sh"
  source "$FUNCTIONS_DIR/website/website_management_create.sh"

  echo "[DEBUG] ✅ setup() đã chạy xong" >&2
}

teardown() {
  [[ -n "$TEST_SANDBOX_DIR" && -d "$TEST_SANDBOX_DIR" ]] && rm -rf "$TEST_SANDBOX_DIR"
}

@test "create website: generates essential structure and files" {
  run website_management_create
  echo "[DEBUG] 💥 Output:\n$output" >&2
  [ "$status" -eq 0 ]
  [ -d "$SITES_DIR/example" ]
  [ -d "$SITES_DIR/example/wordpress" ]
  [ -f "$SITES_DIR/example/docker-compose.yml" ]
  [ -f "$SITES_DIR/example/.env" ]
  [ -f "$SITES_DIR/example/php/php.ini" ]
  [ -f "$SITES_DIR/example/php/php-fpm.conf" ]
  [ -f "$SITES_DIR/example/mariadb/conf.d/custom.cnf" ]
  [ -f "$LOGS_DIR/example-setup.log" ]
}

@test "create website: fails if site already exists" {
  mkdir -p "$SITES_DIR/example"
  run website_management_create
  echo "[DEBUG] 💥 Output:\n$output" >&2
  [ "$status" -ne 0 ]
  [[ "$output" == *"Website"* && "$output" == *"đã tồn tại"* ]]
}
