#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../test_helper/bats-support/load"
load "${BATS_TEST_DIRNAME}/../test_helper/bats-assert/load"

setup() {
  source "${BATS_TEST_DIRNAME}/../../shared/scripts/functions/generate_wp_admin.sh"
}

@test "generate_wp_admin should create ADMIN_USER with prefix admin_ and a random suffix" {
  generate_wp_admin
  [[ "$ADMIN_USER" =~ ^admin_[a-f0-9]{12}$ ]]
}

@test "generate_wp_admin should create ADMIN_PASSWORD with 16 alphanumeric characters" {
  generate_wp_admin
  [[ "$ADMIN_PASSWORD" =~ ^[A-Za-z0-9]{16}$ ]]
}
