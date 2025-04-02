#!/usr/bin/env bats

# ================================================
# ${CHECKMARK} Test: website_restart.bats
# CLI should restart the selected WordPress website
# ================================================

load ../helpers/general.bash

setup() {
  TEST_SITE_NAME="$(generate_test_site_name)"
  TEST_DOMAIN="${TEST_SITE_NAME}.local"
  TEST_PHP_VERSION="8.2"

  # Create site first (without WordPress install)
  bash "$PROJECT_DIR/shared/scripts/cli/website_create.sh" \
    --site_name="$TEST_SITE_NAME" \
    --domain="$TEST_DOMAIN" \
    --php="$TEST_PHP_VERSION"

  # Ensure site is created before restarting
  SITE_DIR="$SITES_DIR/$TEST_SITE_NAME"
  if [ ! -d "$SITE_DIR" ]; then
    echo "${CROSSMARK} Site creation failed!"
    exit 1
  fi
}

teardown() {
  # Remove site folder if exists
  if [[ -d "$SITES_DIR/$TEST_SITE_NAME" ]]; then
    rm -rf "$SITES_DIR/$TEST_SITE_NAME"
  fi
}

@test "website_restart CLI should restart a WordPress site" {
  run bash "$PROJECT_DIR/shared/scripts/cli/website_restart.sh" --site_name="$TEST_SITE_NAME"

  echo "$output"  # Debug the output

  [ "$status" -eq 0 ]
  [[ "$output" == *"has been restarted successfully"* ]]
}
