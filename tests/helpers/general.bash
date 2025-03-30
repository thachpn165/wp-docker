#!/usr/bin/env bash

# ============================
# 🧪 general.bash – For Bats
# Load config + override to test paths
# ============================

# === Auto-detect PROJECT_DIR ===
if [[ -z "$PROJECT_DIR" ]]; then
  SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
  while [[ "$SCRIPT_PATH" != "/" ]]; do
    if [[ -f "$SCRIPT_PATH/src/shared/config/config.sh" ]]; then
      PROJECT_DIR="$SCRIPT_PATH"
      break
    fi
    SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
  done
fi

# ✅ Lưu lại đường dẫn thật của dự án để dùng cho các file gốc
export PROJECT_DIR_ORIGINAL="$PROJECT_DIR"

# === Load original config.sh ===
CONFIG_FILE="$PROJECT_DIR/src/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi
source "$CONFIG_FILE"

# === Override paths for test ===
TEST_SANDBOX_DIR="/tmp/wp-docker-test-$RANDOM"
mkdir -p "$TEST_SANDBOX_DIR"

export PROJECT_DIR="$TEST_SANDBOX_DIR"
export SITES_DIR="$PROJECT_DIR/sites"
export TMP_DIR="$PROJECT_DIR/tmp"
export LOGS_DIR="$PROJECT_DIR/logs"

export TEMPLATES_DIR="$(realpath "$PROJECT_DIR_ORIGINAL/src/shared/templates")"
export FUNCTIONS_DIR="$(realpath "$PROJECT_DIR_ORIGINAL/src/shared/scripts/functions")"
export SCRIPTS_DIR="$(realpath "$PROJECT_DIR_ORIGINAL/src/shared/scripts")"

# === Flags ===
export TEST_MODE=true
export TEST_ALWAYS_READY=true

# === Load all website-related logic ===
source "$FUNCTIONS_DIR/website_loader.sh"

# === Helper: create random site name ===
generate_test_site_name() {
  echo "testsite-$(openssl rand -hex 3 | tr '[:lower:]' '[:upper:]')"
}

# === Assert helper ===
assert_output_contains() {
  local expected="$1"
  [[ "$output" == *"$expected"* ]] || {
    echo "Expected output to contain: $expected"
    echo "Actual output: $output"
    return 1
  }
}
