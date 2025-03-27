#!/usr/bin/env bats

load '../helpers/mock_env.bash'

setup() {
  setup_env

  export TEST_MODE=true
  export TEST_DOMAIN="example.com"
  export TEST_SITE_NAME=""

  # ➕ Gán giá trị fallback cho get_input_or_test_value
  mkdir -p "$(dirname "$FUNCTIONS_DIR/misc_utils.sh")"
  echo 'get_input_or_test_value() { echo "$2"; }' > "$FUNCTIONS_DIR/misc_utils.sh"
  chmod +x "$FUNCTIONS_DIR/misc_utils.sh"

  # 👉 Copy toàn bộ scripts thực tế vào sandbox (không sửa trực tiếp mã nguồn)
  cp -r "$BATS_TEST_DIRNAME/../../src/shared/" "$BASE_DIR/shared"

  # 👉 Mock các thành phần nguy hiểm hoặc gây treo
  mkdir -p "$TEST_SANDBOX_DIR/bin"
  export PATH="$TEST_SANDBOX_DIR/bin:$PATH"

  # 🐳 docker
  cat > "$TEST_SANDBOX_DIR/bin/docker" <<'EOF'
#!/bin/bash
echo "🧪 mock docker $@"
exit 0
EOF

  # 💤 sleep
  cat > "$TEST_SANDBOX_DIR/bin/sleep" <<'EOF'
#!/bin/bash
echo "🧪 skip sleep $@"
exit 0
EOF

  chmod +x "$TEST_SANDBOX_DIR/bin/"*

  # 🐘 Tạo giả file php_versions.txt
  echo "8.3" > "$BASE_DIR/php_versions.txt"

  # 🧠 Ghi đè function php_choose_version thực tế (nếu muốn chắc chắn)
  cat > "$FUNCTIONS_DIR/php/php_choose_version.sh" <<'EOF'
php_choose_version() {
  echo "🧪 mock chọn phiên bản PHP"
  REPLY="8.3"
  return 0
}
EOF

  # 📂 Tạo template thực tế
  mkdir -p "$TEMPLATES_DIR"
  echo 'memory_limit = 256M' > "$TEMPLATES_DIR/php.ini.template"
  echo 'version: "3"' > "$TEMPLATES_DIR/docker-compose.yml.template"

  # 🔧 Tạo script setup-website giả
  mkdir -p "$SCRIPTS_FUNCTIONS_DIR/setup-website"
  echo 'echo "🧪 mock setup-nginx $@"' > "$SCRIPTS_FUNCTIONS_DIR/setup-website/setup-nginx.sh"
  echo 'echo "🧪 mock setup-wordpress $@"' > "$SCRIPTS_FUNCTIONS_DIR/setup-website/setup-wordpress.sh"
  chmod +x "$SCRIPTS_FUNCTIONS_DIR/setup-website/setup-"*

  # ✅ Load script chính cần test
  source "$FUNCTIONS_DIR/website/website_management_create.sh"
}

teardown() {
  [[ -n "$TEST_SANDBOX_DIR" && -d "$TEST_SANDBOX_DIR" ]] && rm -rf "$TEST_SANDBOX_DIR"
}

@test "create website: generates essential structure and files" {
  run website_management_create
  [ "$status" -eq 0 ]
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
