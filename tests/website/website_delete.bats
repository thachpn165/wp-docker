#!/usr/bin/env bats

# ============================================
# ✅ Test: website_delete.bats
# CLI should delete a WordPress website
# ============================================

load "${BATS_TEST_DIRNAME}/../helpers/general.bash"

setup() {
  TEST_SITE_NAME="$(generate_test_site_name)"
  TEST_DOMAIN="${TEST_SITE_NAME}.local"
  TEST_PHP_VERSION="8.2"

  # Tạo site trước để xoá
  run bash "$PROJECT_DIR_ORIGINAL/shared/scripts/cli/website_create.sh" \
    --site_name="$TEST_SITE_NAME" \
    --domain="$TEST_DOMAIN" \
    --php="$TEST_PHP_VERSION" \
    --auto_generate=true

  # Đảm bảo site đã tạo thành công
  [ "$status" -eq 0 ]
}

teardown() {
  # Cleanup nếu site chưa được xoá
  if [[ -d "$SITES_DIR/$TEST_SITE_NAME" ]]; then
    rm -rf "$SITES_DIR/$TEST_SITE_NAME"
  fi

  # Xoá volume mariadb nếu còn
  volume="${TEST_SITE_NAME}_mariadb_data"
  if docker volume ls --format '{{.Name}}' | grep -q "^$volume$"; then
    docker volume rm "$volume" >/dev/null
  fi
}

@test "website_delete CLI should delete a WordPress website" {
  run bash "$PROJECT_DIR_ORIGINAL/shared/scripts/cli/website_delete.sh" \
    --site_name="$TEST_SITE_NAME" \
    --backup=false

  echo "=== OUTPUT START ==="
  echo "$output"
  echo "=== OUTPUT END ==="
  [ "$status" -eq 0 ]
  assert_output_contains "✅ Website '$TEST_SITE_NAME' deleted successfully."

  # Đảm bảo thư mục site đã xoá
  [ ! -d "$SITES_DIR/$TEST_SITE_NAME" ]
}
