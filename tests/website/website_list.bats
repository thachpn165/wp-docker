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

  # Tạo thư mục giả lập site
  mkdir -p "$SITES_DIR/$TEST_SITE_NAME"
}

teardown() {
  teardown_tmp_dir
  cleanup_test_sandbox
}

@test "website_list CLI should display the website list successfully" {
  run bash "$BASE_DIR/shared/scripts/cli/website_list.sh"

  echo "==== OUTPUT ===="
  echo "$output"
  echo "================"

  assert_output_contains "$TEST_SITE_NAME"
  assert_output_contains "✅ Website list display completed."
}
