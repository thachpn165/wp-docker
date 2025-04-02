#!/usr/bin/env bats

# ============================================
# ✅ Test for SSL Self-Signed Certificate Generation
# ============================================
load "${BATS_TEST_DIRNAME}/../helpers/general.bash"

# Setup test environment
setup() {
  TEST_SITE_NAME="testsite-${RANDOM}"
  TEST_SITE_DIR="/tmp/$TEST_SITE_NAME"
  TEST_SSL_DIR="/tmp/test_ssl_directory"
  
  # Chỉ định thư mục SSL cho môi trường test
  export SSL_DIR="$TEST_SSL_DIR"

  # Tạo thư mục SSL tạm thời cho test
  mkdir -p "$TEST_SSL_DIR"

  # Tạo thư mục website giả (chỉ cần thư mục website không cần tạo toàn bộ website)
  mkdir -p "$TEST_SITE_DIR"

  # Gán giá trị SSL_DIR cho test
  export SSL_DIR="$TEST_SSL_DIR"
}

# Teardown the test environment
teardown() {
  # Xóa các thư mục test khi hoàn thành
  if [ -d "$TEST_SITE_DIR" ]; then
    rm -rf "$TEST_SITE_DIR"
  fi
  if [ -d "$TEST_SSL_DIR" ]; then
    rm -rf "$TEST_SSL_DIR"
  fi
}

# Test 1: Check if SSL is generated successfully
@test "SSL certificate should be generated for the selected site" {
  mkdir -p "$TEST_SITE_DIR/$TEST_SITE_NAME"
  run bash "$PROJECT_DIR/shared/scripts/cli/ssl_generate_self_signed.sh" --site_name="$TEST_SITE_NAME"
  echo $output
  # Check if the SSL files are created
  [ "$status" -eq 0 ]
  assert_output_contains "✅ Self-signed SSL certificate has been regenerated successfully"
  echo $output
  # Check if SSL certificate files exist
  [ -f "$SSL_DIR/$TEST_SITE_NAME.crt" ]
  [ -f "$SSL_DIR/$TEST_SITE_NAME.key" ]
}