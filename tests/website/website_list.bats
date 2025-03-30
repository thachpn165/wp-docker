#!/usr/bin/env bats

# =============================================
# ✅ Test: website_list.bats
# CLI should list all existing WordPress websites
# =============================================

load "${BATS_TEST_DIRNAME}/../helpers/general.bash"

setup() {
  TEST_SITE_NAME="$(generate_test_site_name)"
  TEST_DOMAIN="${TEST_SITE_NAME}.local"
  TEST_PHP_VERSION="8.2"

  # Tạo website trước khi test
  bash "$PROJECT_DIR_ORIGINAL/shared/scripts/cli/website_create.sh" \
    --site_name="$TEST_SITE_NAME" \
    --domain="$TEST_DOMAIN" \
    --php="$TEST_PHP_VERSION"
}

teardown() {
  # Xoá website sau khi test
  bash "$PROJECT_DIR_ORIGINAL/shared/scripts/cli/website_delete.sh" \
    --site_name="$TEST_SITE_NAME" --backup=false
   if [[ -z "$TEST_SITE_NAME" ]]; then
    echo "❌ TEST_SITE_NAME is empty!"
    exit 1
   fi
}

@test "website_list CLI should list the created website" {
  run bash "$PROJECT_DIR_ORIGINAL/shared/scripts/cli/website_list.sh"
  
  [ "$status" -eq 0 ]
  assert_output_contains "$TEST_SITE_NAME"
}