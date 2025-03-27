#!/usr/bin/env bats

# 🧪 Test for website_management_create function

load '../helpers/mock_env.bash'

setup() {
  setup_env

  export TEST_MODE=true
  export TEST_DOMAIN="example.com"
  export TEST_SITE_NAME=""

  # ==== Mock docker command via PATH override ====
  mkdir -p "$TEST_SANDBOX_DIR/bin"
  export PATH="$TEST_SANDBOX_DIR/bin:$PATH"

  cat > "$TEST_SANDBOX_DIR/bin/docker" <<'EOF'
#!/bin/bash
echo "🧪 mock docker $@"
exit 0
EOF
  chmod +x "$TEST_SANDBOX_DIR/bin/docker"

  # ==== Tạo các thư mục cần thiết ====
  mkdir -p \
    "$SITES_DIR" \
    "$LOGS_DIR" \
    "$TEMPLATES_DIR" \
    "$FUNCTIONS_DIR/php" \
    "$FUNCTIONS_DIR/website" \
    "$FUNCTIONS_DIR/website/mariadb_utils" \
    "$FUNCTIONS_DIR/nginx" \
    "$FUNCTIONS_DIR/ssl" \
    "$FUNCTIONS_DIR"

  # ==== Mock sleep để bỏ qua chờ 30 giây ====
  echo 'sleep() { return 0; }' > "$FUNCTIONS_DIR/misc_utils.sh"

  # ==== Templates ====
  echo 'memory_limit = 256M' > "$TEMPLATES_DIR/php.ini.template"
  echo 'version: "3"' > "$TEMPLATES_DIR/docker-compose.yml.template"

  # ==== Mock các function phụ ====
  echo 'php_choose_version() { REPLY="8.3"; return 0; }' > "$FUNCTIONS_DIR/php/php_choose_version.sh"
  echo 'website_create_env() { echo "✅ Created .env"; touch "$1/.env"; }' > "$FUNCTIONS_DIR/website/website_create_env.sh"
  echo 'is_directory_exist() { [ -d "$1" ] && return 0 || return 1; }' > "$FUNCTIONS_DIR/file_utils.sh"
  echo 'copy_file() { cp "$1" "$2"; }' >> "$FUNCTIONS_DIR/file_utils.sh"
  echo 'apply_mariadb_config() { touch "$1"; }' > "$FUNCTIONS_DIR/website/mariadb_utils.sh"
  echo 'create_optimized_php_fpm_config() { touch "$1"; }' > "$FUNCTIONS_DIR/php/php_utils.sh"
  echo 'update_nginx_override_mounts() { return 0; }' > "$FUNCTIONS_DIR/nginx/nginx_utils.sh"
  echo 'generate_ssl_cert() { echo "✅ Fake SSL created"; }' > "$FUNCTIONS_DIR/ssl/ssl_utils.sh"
  echo 'nginx_restart() { echo "✅ nginx restarted"; }' > "$FUNCTIONS_DIR/nginx/nginx_restart.sh"
  echo 'run_in_dir() { (cd "$1" && shift && "$@"); }' >> "$FUNCTIONS_DIR/file_utils.sh"
  echo 'is_container_running() { return 0; }' >> "$FUNCTIONS_DIR/docker_utils.sh"
  # Tạo file setup-nginx.sh và setup-wordpress.sh giả để tránh treo
  mkdir -p "$SCRIPTS_FUNCTIONS_DIR/setup-website"
  echo 'echo "🧪 mock setup-nginx.sh"' > "$SCRIPTS_FUNCTIONS_DIR/setup-website/setup-nginx.sh"
  echo 'echo "🧪 mock setup-wordpress.sh $1"' > "$SCRIPTS_FUNCTIONS_DIR/setup-website/setup-wordpress.sh"
  chmod +x "$SCRIPTS_FUNCTIONS_DIR/setup-website/setup-nginx.sh"
  chmod +x "$SCRIPTS_FUNCTIONS_DIR/setup-website/setup-wordpress.sh"
  # ==== Copy file cần test ====
  mkdir -p "$FUNCTIONS_DIR/website"
  cp "$BATS_TEST_DIRNAME/../../src/shared/scripts/functions/website/website_management_create.sh" "$FUNCTIONS_DIR/website/"

  source "$FUNCTIONS_DIR/website/website_management_create.sh"
}

teardown() {
  [[ -n "$TEST_SANDBOX_DIR" && -d "$TEST_SANDBOX_DIR" ]] && rm -rf "$TEST_SANDBOX_DIR"
}

@test "create website: generates essential structure and files" {
  run website_management_create
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
  [ "$status" -ne 0 ]
  [[ "$output" =~ "Website 'example' đã tồn tại." ]]
}
