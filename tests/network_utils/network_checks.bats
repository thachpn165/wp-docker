#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../test_helper/bats-support/load"
load "${BATS_TEST_DIRNAME}/../test_helper/bats-assert/load"

setup() {
  SHARED_FUNCTIONS_DIR="${BATS_TEST_DIRNAME}/../../shared/scripts/functions"
  source "$SHARED_FUNCTIONS_DIR/network_utils.sh"
}

@test "is_internet_connected should return 0 if ping works" {
  run is_internet_connected
  assert_success
}

@test "is_domain_resolvable should return 0 for google.com" {
  run is_domain_resolvable "google.com"
  assert_success
}