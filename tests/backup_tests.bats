#!/usr/bin/env bats

@test "Kiểm tra xem backup script có tồn tại không" {
  run test -f shared/scripts/functions/backup-manager/backup_database.sh
  [ "$status" -eq 0 ]
}

@test "Chạy thử backup script" {
  run bash shared/scripts/functions/backup-manager/backup_database.sh --test
  [ "$status" -eq 0 ]
}
