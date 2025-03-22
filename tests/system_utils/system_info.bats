#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../test_helper/bats-support/load"
load "${BATS_TEST_DIRNAME}/../test_helper/bats-assert/load"

setup() {
  SHARED_FUNCTIONS_DIR="${BATS_TEST_DIRNAME}/../../shared/scripts/functions"
  source "$SHARED_FUNCTIONS_DIR/system_utils.sh"
}

@test "get_total_ram should return a positive integer" {
  result="$(get_total_ram)"
  echo "Total RAM: $result"
  [[ "$result" =~ ^[0-9]+$ ]] && [ "$result" -gt 0 ]
}

@test "get_total_cpu should return a positive integer" {
  result="$(get_total_cpu)"
  echo "Total CPU: $result"
  [[ "$result" =~ ^[0-9]+$ ]] && [ "$result" -gt 0 ]
}
