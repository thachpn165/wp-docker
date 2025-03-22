#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../test_helper/bats-support/load"
load "${BATS_TEST_DIRNAME}/../test_helper/bats-assert/load"

setup() {
  export RCLONE_CONFIG_FILE="/tmp/fake_rclone.conf"
  mkdir -p /tmp/shared/config/rclone
  cp /dev/null "$RCLONE_CONFIG_FILE"

  cat <<EOF > "$RCLONE_CONFIG_FILE"
[drive1]
type = drive

[backup-s3]
type = s3
EOF

  export SCRIPTS_FUNCTIONS_DIR="${BATS_TEST_DIRNAME}/../../shared/scripts/functions"
  source "$SCRIPTS_FUNCTIONS_DIR/file_utils.sh"
  source "$SCRIPTS_FUNCTIONS_DIR/rclone/manage_rclone.sh"
}

teardown() {
  rm -f "$RCLONE_CONFIG_FILE"
}

@test "rclone_storage_list should return defined storage names" {
  run rclone_storage_list
  assert_success
  assert_output --partial "drive1"
  assert_output --partial "backup-s3"
}
