#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../test_helper/bats-support/load"
load "${BATS_TEST_DIRNAME}/../test_helper/bats-assert/load"

setup() {
  SHARED_FUNCTIONS_DIR="${BATS_TEST_DIRNAME}/../../shared/scripts/functions"
  source "$SHARED_FUNCTIONS_DIR/ssl_utils.sh"

  export TEST_DOMAIN="test.local"
  export SSL_DIR="/tmp/ssl-test"
  mkdir -p "$SSL_DIR"
}

teardown() {
  rm -rf "$SSL_DIR"
}

@test "generate_ssl_cert should create .crt and .key files" {
  generate_ssl_cert "$TEST_DOMAIN" "$SSL_DIR"

  assert [ -f "$SSL_DIR/$TEST_DOMAIN.crt" ]
  assert [ -f "$SSL_DIR/$TEST_DOMAIN.key" ]
}

@test "is_ssl_cert_valid should return 0 for valid cert" {
  generate_ssl_cert "$TEST_DOMAIN" "$SSL_DIR"

  run is_ssl_cert_valid "$SSL_DIR/$TEST_DOMAIN.crt"
  assert_success
}