#!/usr/bin/env bats

# =============================================
# ${CHECKMARK} Test: website_wordpress_setup.bats
# CLI should install WordPress with given admin info
# =============================================

load "${BATS_TEST_DIRNAME}/../helpers/general.bash"

setup() {
  TEST_SITE_NAME="$(generate_test_site_name)"
  TEST_DOMAIN="${TEST_SITE_NAME}.local"
  TEST_PHP_VERSION="8.2"

  # 👉 Tạo site trước (chưa cài WordPress)
  bash "$PROJECT_DIR_ORIGINAL/shared/scripts/cli/website_create.sh" \
    --site_name="$TEST_SITE_NAME" \
    --domain="$TEST_DOMAIN" \
    --php="$TEST_PHP_VERSION"

  # 👉 Xoá wp-info để test cài lại WordPress
  rm -f "$SITES_DIR/$TEST_SITE_NAME/.wp-info"
}

teardown() {
  if [[ -d "$SITES_DIR/$TEST_SITE_NAME" ]]; then
    rm -rf "$SITES_DIR/$TEST_SITE_NAME"
  fi

  volume="${TEST_SITE_NAME}_mariadb_data"
  if docker volume ls --format '{{.Name}}' | grep -q "^$volume$"; then
    docker volume rm "$volume" >/dev/null
  fi
}

@test "website_wordpress_setup CLI should install WordPress with admin credentials" {
  ADMIN_USER="testadmin"
  ADMIN_PASS="Secret123!"
  ADMIN_EMAIL="admin@example.com"

  run bash "$PROJECT_DIR_ORIGINAL/shared/scripts/cli/website_setup_wordpress.sh" \
    --site_name="$TEST_SITE_NAME" \
    --user="$ADMIN_USER" \
    --pass="$ADMIN_PASS" \
    --email="$ADMIN_EMAIL"

  [ "$status" -eq 0 ]
  assert_output_contains "Site URL"
  assert_output_contains "$ADMIN_USER"
  assert_output_contains "$ADMIN_EMAIL"
}