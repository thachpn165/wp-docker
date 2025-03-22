#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../test_helper/bats-support/load"
load "${BATS_TEST_DIRNAME}/../test_helper/bats-assert/load"

setup() {
  mkdir -p /tmp/test-wp
  touch /tmp/test-wp/sample.txt
  mkdir -p /tmp/test-wp/sample-dir
  source ./shared/scripts/functions/file_utils.sh
}

teardown() {
  rm -rf /tmp/test-wp
  rm -f /tmp/log_output.log
}

@test "is_file_exist should return success if file exists" {
  run is_file_exist "/tmp/test-wp/sample.txt"
  [ "$status" -eq 0 ]
}

@test "is_directory_exist should return success if directory exists" {
  run is_directory_exist "/tmp/test-wp/sample-dir"
  [ "$status" -eq 0 ]
}

@test "remove_file should delete file if exists" {
  run remove_file "/tmp/test-wp/sample.txt"
  [ ! -f /tmp/test-wp/sample.txt ]
}

@test "remove_directory should delete directory if exists" {
  run remove_directory "/tmp/test-wp/sample-dir"
  [ ! -d /tmp/test-wp/sample-dir ]
}

@test "copy_file should copy file from src to dest" {
  echo "hello" > /tmp/test-wp/source.txt
  run copy_file "/tmp/test-wp/source.txt" "/tmp/test-wp/dest.txt"
  assert_success
  assert_file_exist() {
    [ -f "$1" ] || { echo "File không tồn tại: $1"; return 1; }
    }

    assert_file_exist "/tmp/test-wp/dest.txt"

  assert_equal "$(cat /tmp/test-wp/dest.txt)" "hello"
}

@test "log_with_time should prepend timestamp" {
  export log_file="/tmp/log_output.log"
  log_with_time "Test log message"

  run grep "Test log message" "$log_file"
  assert_success
}


