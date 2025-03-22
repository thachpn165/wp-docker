#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../test_helper/bats-support/load"
load "${BATS_TEST_DIRNAME}/../test_helper/bats-assert/load"

setup() {
  # Ghi đè các hàm phụ trợ để test không phụ thuộc hệ thống thật
  get_total_ram() {
    echo 2048  # Giả định 2GB RAM
  }

  get_total_cpu() {
    echo 2  # Giả định 2 CPU
  }

  # Source file gốc sau khi đã có hàm mock
  source ./shared/scripts/functions/db_utils.sh
}

@test "calculate_mariadb_config should calculate reasonable MariaDB config values" {
    calculate_mariadb_config
    [ "$max_connections" -ge 100 ]
  [ "$innodb_buffer_pool_size" -ge 256 ]
  [ "$innodb_log_file_size" -ge 64 ]
  [ "$table_open_cache" -ge 400 ]
  [ "$thread_cache_size" -ge 1 ]

  echo "max_connections = $max_connections"
  echo "innodb_buffer_pool_size = $innodb_buffer_pool_size"
  echo "innodb_log_file_size = $innodb_log_file_size"
  echo "table_open_cache = $table_open_cache"
  echo "thread_cache_size = $thread_cache_size"
} 
