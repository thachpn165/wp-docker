#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../test_helper/bats-support/load"
load "${BATS_TEST_DIRNAME}/../test_helper/bats-assert/load"

setup() {
  export SITE_NAME="test-site"
  export SITES_DIR="/tmp/sites"
  export BACKUP_DIR="$SITES_DIR/$SITE_NAME/backups"
  mkdir -p "$BACKUP_DIR"

  # File mới: sẽ KHÔNG bị xoá
  touch "$BACKUP_DIR/recent.sql"

  # File cũ: sẽ bị xoá
  if date -v -5d "+%Y%m%d%H%M.%S" &>/dev/null; then
    # macOS
    timestamp=$(date -v -5d "+%Y%m%d%H%M.%S")
  else
    # Linux
    timestamp=$(date -d "5 days ago" "+%Y%m%d%H%M.%S")
  fi
  touch -t "$timestamp" "$BACKUP_DIR/old.sql"

  SHARED_FUNCTIONS_DIR="${BATS_TEST_DIRNAME}/../../shared/scripts/functions"
  source "$SHARED_FUNCTIONS_DIR/backup-manager/cleanup_backups.sh"
}

teardown() {
  rm -rf /tmp/sites
}

@test "cleanup_backups should delete old files and keep recent ones" {
  run cleanup_backups "$SITE_NAME" 3
  assert_success
  assert_output --partial "Đã xóa: $BACKUP_DIR/old.sql"
  assert [ ! -f "$BACKUP_DIR/old.sql" ]
  assert [ -f "$BACKUP_DIR/recent.sql" ]
}