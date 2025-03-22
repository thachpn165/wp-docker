#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../test_helper/bats-support/load"
load "${BATS_TEST_DIRNAME}/../test_helper/bats-assert/load"

setup() {
  export SITE_NAME="test-site"
  export SITES_DIR="/tmp/sites"
  export BACKUP_DIR="$SITES_DIR/$SITE_NAME/backups"
  mkdir -p "$BACKUP_DIR"

  # Fake docker exec to simulate successful mysqldump
  mkdir -p /tmp/fakebin
  export PATH="/tmp/fakebin:$PATH"

  cat <<'EOF' > /tmp/fakebin/docker
#!/bin/bash
if [[ "$1" == "exec" ]]; then
  cat <<SQL
-- Mock MySQL dump
CREATE TABLE test (id INT);
SQL
fi
EOF
  chmod +x /tmp/fakebin/docker

  SHARED_FUNCTIONS_DIR="${BATS_TEST_DIRNAME}/../../shared/scripts/functions"
  source "$SHARED_FUNCTIONS_DIR/backup-manager/backup_database.sh"
}

teardown() {
  rm -rf /tmp/sites
  rm -rf /tmp/fakebin
}

@test "backup_database should create .sql file with correct path" {
  run backup_database "$SITE_NAME" "mock_db" "user" "pass"
  assert_success
  assert_output --partial "$SITE_NAME/backups/db-$SITE_NAME"

  filepath=$(echo "$output" | tail -n 1)
  assert [ -f "$filepath" ]
}