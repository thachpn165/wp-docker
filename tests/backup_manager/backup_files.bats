#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../test_helper/bats-support/load"
load "${BATS_TEST_DIRNAME}/../test_helper/bats-assert/load"

setup() {
  export SITE_NAME="test-site"
  export SITES_DIR="/tmp/sites"
  export BACKUP_DIR="$SITES_DIR/$SITE_NAME/backups"
  export WEB_ROOT="/tmp/code"

  mkdir -p "$BACKUP_DIR"
  mkdir -p "$WEB_ROOT"
  echo "<?php echo 'Hello'; ?>" > "$WEB_ROOT/index.php"

  SHARED_FUNCTIONS_DIR="${BATS_TEST_DIRNAME}/../../shared/scripts/functions"
  source "$SHARED_FUNCTIONS_DIR/backup-manager/backup_files.sh"
  source "$SHARED_FUNCTIONS_DIR/file_utils.sh"
}

teardown() {
  rm -rf /tmp/sites
  rm -rf /tmp/code
}

@test "backup_files should create .tar.gz file with correct path" {
  run backup_files "$SITE_NAME" "$WEB_ROOT"
  assert_success
  assert_output --partial "$SITE_NAME/backups/files-$SITE_NAME"

  filepath=$(echo "$output" | tail -n 1)
  assert [ -f "$filepath" ]
}
