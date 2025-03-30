#!/usr/bin/env bats

# ============================================
# ✅ website_info.bats – Test displaying website information
# ============================================

load ../helpers/general.bash

setup() {
  TEST_SITE_NAME="testsite-$(openssl rand -hex 3 | tr '[:lower:]' '[:upper:]')"
  TEST_SITE_URL="${TEST_SITE_NAME}.local"
  TEST_PHP_VERSION="8.2"

  # Create website first (without WordPress install)
  bash "$PROJECT_DIR/shared/scripts/cli/website_create.sh" \
    --site_name="$TEST_SITE_NAME" \
    --domain="$TEST_SITE_URL" \
    --php="$TEST_PHP_VERSION"

  # Wait to ensure the site is created
  sleep 2
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

@test "website_info CLI should display the correct information for the site" {
  run bash "$PROJECT_DIR/shared/scripts/cli/website_info.sh" --site_name="$TEST_SITE_NAME"
  [ "$status" -eq 0 ]
  assert_output_contains "Website Information for"
}

@test "website_info CLI should handle missing site_name" {
  run bash "$PROJECT_DIR/shared/scripts/cli/website_info.sh"
  [ "$status" -eq 1 ]
  assert_output_contains "❌ Missing required --site_name parameter"
}