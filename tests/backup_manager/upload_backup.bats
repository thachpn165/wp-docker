#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../test_helper/bats-support/load"
load "${BATS_TEST_DIRNAME}/../test_helper/bats-assert/load"

# Cấu hình test
setup() {
  export SCRIPTS_FUNCTIONS_DIR="shared/scripts/functions"
  export SITES_DIR="/tmp/test-sites"
  export RCLONE_CONFIG_FILE="$PWD/test-data/rclone.conf"
  export TEST_SITE="mysite"
  export BACKUP_DIR="$SITES_DIR/$TEST_SITE/backups"
  export LOG_DIR="$SITES_DIR/$TEST_SITE/logs"

  mkdir -p "$BACKUP_DIR" "$LOG_DIR"

  # Tạo file giả lập
  echo "dummy database content" > "$BACKUP_DIR/db.sql"
  echo "dummy code content" > "$BACKUP_DIR/files.tar.gz"

  # File cấu hình rclone giả
  mkdir -p "$(dirname "$RCLONE_CONFIG_FILE")"
  cat <<EOF > "$RCLONE_CONFIG_FILE"
[myteststorage]
type = local
EOF

  # Override biến môi trường cho script upload
  export RED=""
  export GREEN=""
  export BLUE=""
  export YELLOW=""
  export NC=""
}

teardown() {
  rm -rf "$SITES_DIR"
  rm -f "$RCLONE_CONFIG_FILE"
}

@test "❌ Thiếu tham số storage sẽ báo lỗi" {
  run bash "$SCRIPTS_FUNCTIONS_DIR/rclone/upload_backup.sh"
  assert_failure
  assert_output --partial "❌ Thiếu tham số storage"
}

@test "❌ Storage không tồn tại trong rclone.conf sẽ báo lỗi" {
  run bash "$SCRIPTS_FUNCTIONS_DIR/rclone/upload_backup.sh" "invalidstorage" "$BACKUP_DIR/db.sql"
  assert_failure
  assert_output --partial "Không tìm thấy cấu hình Rclone"
}

@test "✅ Upload thành công nếu file và storage hợp lệ (mock rclone)" {
  # Tạo script giả rclone (mock)
  mkdir -p ./bin
  cat <<EOF > ./bin/rclone
#!/bin/bash
echo "Fake upload: \$@"
exit 0
EOF
  chmod +x ./bin/rclone
  export PATH="./bin:\$PATH"

  run bash "$SCRIPTS_FUNCTIONS_DIR/rclone/upload_backup.sh" "myteststorage" "$BACKUP_DIR/db.sql" "$BACKUP_DIR/files.tar.gz"

  assert_success
  assert_output --partial "📂 Danh sách file sẽ upload"
  assert_output --partial "✅ Upload thành công"

  # Kiểm tra log được tạo
  assert_file_exist "$LOG_DIR/rclone-upload.log"
}

