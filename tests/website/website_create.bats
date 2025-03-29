#!/usr/bin/env bats

load ../helpers/sandbox.bash
load ../helpers/mock_env.bash
load ../helpers/general.bash

setup() {
  setup_env
  setup_tmp_dir

  export TEST_MODE=true
  export DEV_MODE=true

  export TEST_SITE_NAME="testsite-$(date +%s%N | tail -c 6)"
  export TEST_DOMAIN="${TEST_SITE_NAME}.local"

  # Giả lập file php_versions.txt
  mkdir -p "$PROJECT_DIR"
  cat > "$PROJECT_DIR/php_versions.txt" <<EOF
8.0
8.1
8.2
EOF

  # Giả lập templates
  mkdir -p "$TEMPLATES_DIR"
  cat > "$TEMPLATES_DIR/php.ini.template" <<EOF
; mock php.ini
EOF

  cat > "$TEMPLATES_DIR/docker-compose.yml.template" <<EOF
version: '3.8'
services:
  php:
    image: bitnami/php-fpm:\${PHP_VERSION}
EOF

  cat > "$TEMPLATES_DIR/nginx-proxy.conf.template" <<EOF
server {
  server_name \${DOMAIN};
  location / {
    proxy_pass http://\${PHP_CONTAINER}:9000;
  }
}
EOF

  # Giả lập nginx-proxy dir
  mkdir -p "$NGINX_PROXY_DIR"
}

teardown() {
  teardown_tmp_dir
  cleanup_test_sandbox
}

@test "website_create CLI should create a WordPress site successfully" {
  # === MOCK toàn bộ để test không bị treo ===
  run_unless_test() { echo "[MOCK run_unless_test] $*"; return 0; }
  php_choose_version() { REPLY="8.0"; echo "[TEST_MODE] Selected PHP version: $REPLY"; return 0; }
  is_container_running() { return 0; }
  generate_ssl_cert() { echo "[MOCK] SSL created"; return 0; }
  nginx_restart() { echo "[MOCK] NGINX restarted"; return 0; }
  update_nginx_override_mounts() { echo "[MOCK] update_nginx_override_mounts"; return 0; }
  copy_file() { echo "[MOCK] copy_file $*"; return 0; }
  apply_mariadb_config() { echo "[MOCK] apply_mariadb_config"; return 0; }
  create_optimized_php_fpm_config() { echo "[MOCK] php_fpm_conf"; return 0; }
  website_create_env() {
    echo "[MOCK] env created with args: $*"
    return 0
  }
  run_in_dir() { echo "[MOCK] run_in_dir $*"; return 0; }

export -f run_unless_test php_choose_version is_container_running \
  generate_ssl_cert nginx_restart update_nginx_override_mounts \
  copy_file apply_mariadb_config create_optimized_php_fpm_config \
  website_create_env run_in_dir


  run bash "$BASE_DIR/shared/scripts/cli/website_create.sh"

  echo "==== OUTPUT ===="
  echo "$output"
  echo "================"

  assert_output_contains "✅ DONE_CREATE_WEBSITE: $TEST_SITE_NAME"
}
