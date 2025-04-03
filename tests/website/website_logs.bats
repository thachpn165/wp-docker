#!/usr/bin/env bats

# ================================================
# ${CHECKMARK} Test: website_logs.bats
# CLI should display logs for the given site and log type
# ================================================

load ../helpers/general.bash

setup() {
  # Tạo tên website thử nghiệm
  TEST_SITE_NAME="$(generate_test_site_name)"
  TEST_LOG_TYPE="access"
  
  # Tạo một website giả lập
  # Đây là ví dụ, bạn có thể thay thế logic tạo website cho phù hợp
  run bash "$PROJECT_DIR/shared/scripts/cli/website_create.sh" \
    --site_name="$TEST_SITE_NAME" \
    --domain="${TEST_SITE_NAME}.local" \
    --php="8.2"
  
  # Đảm bảo website đã được tạo thành công
  assert_output_contains "${CHECKMARK} DONE_CREATE_WEBSITE: $TEST_SITE_NAME"
}

teardown() {
  # Xoá website nếu đã tạo
  if [[ -d "$SITES_DIR/$TEST_SITE_NAME" ]]; then
    rm -rf "$SITES_DIR/$TEST_SITE_NAME"
  fi
}

@test "website_logs CLI should display the correct logs for the site" {
  # Chạy lệnh hiển thị logs
  run bash "$PROJECT_DIR/shared/scripts/cli/website_logs.sh" --site_name="$TEST_SITE_NAME" --log_type="$TEST_LOG_TYPE"

  # Kiểm tra xem có thông tin liên quan đến site và log type
  [ "$status" -eq 0 ]
  assert_output_contains "⏳ Loading log"
  assert_output_contains "Following Access Log"
  assert_output_contains "$TEST_SITE_NAME"
  assert_output_contains "$TEST_LOG_TYPE"
}

@test "website_logs CLI should handle missing site_name" {
  # Chạy lệnh mà không có tham số --site_name
  run bash "$PROJECT_DIR/shared/scripts/cli/website_logs.sh" --log_type="$TEST_LOG_TYPE"

  # Kiểm tra lỗi khi thiếu tham số --site_name
  [ "$status" -ne 0 ]
  assert_output_contains "${CROSSMARK} site_name is not set. Please provide a valid site name."
}

@test "website_logs CLI should handle missing log_type" {
  # Chạy lệnh mà không có tham số --log_type
  run bash "$PROJECT_DIR/shared/scripts/cli/website_logs.sh" --site_name="$TEST_SITE_NAME"

  # Kiểm tra lỗi khi thiếu tham số --log_type
  [ "$status" -ne 0 ]
  assert_output_contains "${CROSSMARK} log_type is required. Please specify access or error log."
}