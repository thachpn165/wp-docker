#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../test_helper/bats-support/load"
load "${BATS_TEST_DIRNAME}/../test_helper/bats-assert/load"

setup() {
  SHARED_FUNCTIONS_DIR="${BATS_TEST_DIRNAME}/../../shared/scripts/functions"
  source "$SHARED_FUNCTIONS_DIR/php_utils.sh"
}

@test "calculate_php_fpm_values should return 4 numeric values" {
  result="$(calculate_php_fpm_values 2048 2)"

  # Tách kết quả thành từng phần
  IFS=' ' read -r max_children start_servers min_spare max_spare <<< "$result"

  # Kiểm tra xem có đúng 4 số và lớn hơn 0
  [[ "$max_children" =~ ^[0-9]+$ ]] && [ "$max_children" -gt 0 ]
  [[ "$start_servers" =~ ^[0-9]+$ ]] && [ "$start_servers" -gt 0 ]
  [[ "$min_spare" =~ ^[0-9]+$ ]] && [ "$min_spare" -ge 1 ]
  [[ "$max_spare" =~ ^[0-9]+$ ]] && [ "$max_spare" -ge 4 ]
}
