#!/usr/bin/env bash

# ============================
# 🧪 general.bash – For Bats
# Load config + override for test paths
# ============================

# === Hard-code đường dẫn gốc đến source code ===
export PROJECT_DIR_ORIGINAL="$(realpath "$BATS_TEST_DIRNAME/../../src")"
export PROJECT_DIR="$PROJECT_DIR_ORIGINAL"

# ${CHECKMARK} Load config gốc
CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "${CROSSMARK} Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi
source "$CONFIG_FILE"

# === Override thư mục test sandbox (chỉ ảnh hưởng dữ liệu) ===
export PROJECT_DIR_TEST="/tmp/wp-docker-test-$RANDOM"
mkdir -p "$PROJECT_DIR_TEST"

export SITES_DIR="$PROJECT_DIR_TEST/sites"
export TMP_DIR="$PROJECT_DIR_TEST/tmp"
export LOGS_DIR="$PROJECT_DIR_TEST/logs"

# === Giữ nguyên các thư mục templates/functions/scripts từ project thật ===
export TEMPLATES_DIR="$PROJECT_DIR/shared/templates"
export FUNCTIONS_DIR="$PROJECT_DIR/shared/scripts/functions"
export SCRIPTS_DIR="$PROJECT_DIR/shared/scripts"

# === Cờ test mode ===
export TEST_MODE=true
export TEST_ALWAYS_READY=true

# ${CHECKMARK} Load toàn bộ logic quản lý website
source "$FUNCTIONS_DIR/website_loader.sh"

# === Helper: tạo site name random ===
generate_test_site_name() {
  echo "testsite-$(openssl rand -hex 3 | tr '[:lower:]' '[:upper:]')"
}

# === Helper: assert output chứa text ===
assert_output_contains() {
  local expected="$1"
  [[ "$output" == *"$expected"* ]] || {
    echo "Expected output to contain: $expected"
    echo "Actual output: $output"
    return 1
  }
}

# === ${CHECKMARK} Mocks for Docker CLI when TEST_MODE ===
if [[ "$TEST_MODE" == true ]]; then
  TEST_MOCK_BIN_DIR="$PROJECT_DIR_TEST/mocks"
  mkdir -p "$TEST_MOCK_BIN_DIR"

  # Mock docker exec (giả lập chạy thành công)
  cat > "$TEST_MOCK_BIN_DIR/docker" <<'EOF'
#!/bin/bash
if [[ "$1" == "exec" ]]; then
  echo "[MOCK] docker exec $@"
  exit 0
elif [[ "$1" == "volume" && "$2" == "rm" ]]; then
  echo "[MOCK] docker volume rm $@"
  exit 0
elif [[ "$1" == "ps" ]]; then
  echo "[MOCK] docker ps"
  exit 0
elif [[ "$1" == "restart" ]]; then
  echo "[MOCK] docker restart $@"
  exit 0
else
  echo "[MOCK] docker $@"
  exit 0
fi
EOF

  chmod +x "$TEST_MOCK_BIN_DIR/docker"

  # Mock wp CLI (giả lập chạy thành công)
  cat > "$TEST_MOCK_BIN_DIR/wp" <<'EOF'
#!/bin/bash
echo "[MOCK] wp $@"
exit 0
EOF

  chmod +x "$TEST_MOCK_BIN_DIR/wp"

  # Mock docker-compose.override.yml for NGINX
  cat > "$PROJECT_DIR_TEST/mocks/docker-compose.override.yml" <<'EOF'
version: "3"
services:
  nginx-proxy:
    volumes:
      - ../../sites/$domain/wordpress:/var/www/$domain
      - ../../sites/$domain/logs:/var/www/logs/$domain
EOF

  export PATH="$TEST_MOCK_BIN_DIR:$PATH"
fi