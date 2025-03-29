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
  export SITE_DIR="$SITES_DIR/$TEST_SITE_NAME"
  export ENV_FILE="$SITE_DIR/.env"

  mkdir -p "$SITE_DIR/wordpress" "$SITE_DIR/logs" "$SITE_DIR/backups"
  echo "DOMAIN=$TEST_DOMAIN" > "$ENV_FILE"
  echo "MYSQL_DATABASE=db" >> "$ENV_FILE"
  echo "MYSQL_USER=user" >> "$ENV_FILE"
  echo "MYSQL_PASSWORD=pass" >> "$ENV_FILE"

  mkdir -p "$SSL_DIR"
  touch "$SSL_DIR/$TEST_DOMAIN.crt" "$SSL_DIR/$TEST_DOMAIN.key"

  # Giả lập file conf NGINX
  mkdir -p "$NGINX_PROXY_DIR/conf.d"
  touch "$NGINX_PROXY_DIR/conf.d/$TEST_SITE_NAME.conf"

  # Giả lập override mounts
  mkdir -p "$NGINX_PROXY_DIR"
  cat > "$NGINX_PROXY_DIR/docker-compose.override.yml" <<EOF
services:
  php:
    volumes:
      - ../../sites/$TEST_SITE_NAME/wordpress:/var/www/$TEST_SITE_NAME
      - ../../sites/$TEST_SITE_NAME/logs:/var/www/logs/$TEST_SITE_NAME
EOF
}

teardown() {
  teardown_tmp_dir
  cleanup_test_sandbox
}

@test "website_delete CLI should delete WordPress site successfully" {
  # === Mock tất cả các hàm có hành vi nguy hiểm ===
  confirm_action() { return 0; }  # luôn xác nhận
  remove_directory() { echo "[MOCK] remove dir $1"; return 0; }
  remove_file() { echo "[MOCK] remove file $1"; return 0; }
  remove_volume() { echo "[MOCK] remove volume $1"; return 0; }
  run_in_dir() { echo "[MOCK] run in dir $*"; return 0; }
  nginx_restart() { echo "[MOCK] restart nginx"; return 0; }

  export -f confirm_action remove_directory remove_file remove_volume run_in_dir nginx_restart

  run bash "$BASE_DIR/shared/scripts/cli/website_delete.sh"

  echo "==== OUTPUT ===="
  echo "$output"
  echo "================"

  assert_output_contains "✅ Website '$TEST_SITE_NAME' deleted successfully."
}
