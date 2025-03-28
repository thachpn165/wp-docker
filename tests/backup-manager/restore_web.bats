#!/usr/bin/env bats

# ✅ Bật chế độ test
export TEST_MODE=true

# ✅ Source mock môi trường test
source "${BATS_TEST_DIRNAME}/../helpers/mock_env.bash"


setup() {
  setup_env

  # ✅ Mock giá trị SITE_NAME cho test
  export SITE_NAME="demo-site"
  
  # ✅ Tạo folder và file cần thiết
  site_name="$SITE_NAME"
  SITE_DIR="$SITES_DIR/$site_name"
  mkdir -p "$SITE_DIR/backups"

  # ✅ Tạo file backup thật
  CODE_BACKUP_FILE="$SITE_DIR/backups/files-$site_name-$(date +%Y%m%d-%H%M%S).tar.gz"
  DB_BACKUP_FILE="$SITE_DIR/backups/db-$site_name-$(date +%Y%m%d-%H%M%S).sql"
  touch "$CODE_BACKUP_FILE"
  echo "DROP DATABASE IF EXISTS demo_db;" > "$DB_BACKUP_FILE"

  echo "MYSQL_ROOT_PASSWORD=123456" > "$SITE_DIR/.env"
  echo "MYSQL_DATABASE=demo_db" >> "$SITE_DIR/.env"

  # ✅ Tạo container MariaDB giả để restore thử
  docker run --name "$site_name-mariadb" -e MYSQL_ROOT_PASSWORD=123456 -d --rm mariadb:10.6 --skip-grant-tables

  # ✅ Source hàm gốc
  source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/backup_restore_web.sh"
}

teardown() {
  docker rm -f "demo-site-mariadb" >/dev/null 2>&1
  rm -rf "$BASE_DIR"
}

@test "backup_restore_web runs real restore functions successfully" {
  # Simulate user input for restore
  run backup_restore_web <<< $"1\ny\n$(basename "$CODE_BACKUP_FILE")\ny\n$(basename "$DB_BACKUP_FILE")"

  echo "DEBUG Output:"
  echo "$output"

  # Check if the expected messages are present in the output
  [[ "$output" =~ "KHÔI PHỤC WEBSITE" ]]
  [[ "$output" =~ "Đã tìm thấy file backup" ]]
  [[ "$output" =~ "✅ Hoàn tất khôi phục website" ]]
}

