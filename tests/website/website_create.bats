#!/usr/bin/env bats

# ================================================
# ✅ Test: website_create.bats
# CLI should create a WordPress site successfully
# ================================================

load "${BATS_TEST_DIRNAME}/../helpers/general.bash"

setup() {
  load_env_if_exists
  TEST_SITE_NAME="$(generate_test_site_name)"
  TEST_DOMAIN="${TEST_SITE_NAME}.local"
  TEST_PHP_VERSION="8.2"
}

teardown() {
  # Remove site folder if exists
  if [[ -d "$SITES_DIR/$TEST_SITE_NAME" ]]; then
    rm -rf "$SITES_DIR/$TEST_SITE_NAME"
  fi

  # Remove MariaDB volume if exists
  volume="${TEST_SITE_NAME}_mariadb_data"
  if docker volume ls --format '{{.Name}}' | grep -q "^$volume$"; then
    docker volume rm "$volume" >/dev/null
  fi
}

@test "echo debug" {
  echo "✅ PROJECT_DIR_ORIGINAL=$PROJECT_DIR_ORIGINAL"
  echo "✅ PROJECT_DIR=$PROJECT_DIR"
  echo "✅ SITES_DIR=$SITES_DIR"
}

#@test "website_create CLI should create a WordPress site successfully" {
#  run bash "$PROJECT_DIR_ORIGINAL/src/shared/scripts/cli/website_create.sh" \
#    --site_name="$TEST_SITE_NAME" \
#    --domain="$TEST_DOMAIN" \
#    --php="$TEST_PHP_VERSION"
#
#  [ "$status" -eq 0 ]
#  [[ "$output" == *"✅ DONE_CREATE_WEBSITE: $TEST_SITE_NAME"* ]]
#}

