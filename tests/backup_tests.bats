#!/usr/bin/env bats

# Định nghĩa biến môi trường cho test
setup() {
    export TEST_SITE_NAME="testsite"
    export TEST_STORAGE="teststorage"
    export BACKUP_SCRIPT="shared/scripts/functions/backup-scheduler/backup_runner.sh"
    export BACKUP_DIR="sites/$TEST_SITE_NAME/backups"
    export LOG_FILE="sites/$TEST_SITE_NAME/logs/wp-backup.log"
    export RCLONE_CONFIG_FILE="shared/config/rclone/rclone.conf"

    # Tạo thư mục giả lập môi trường test
    mkdir -p "$BACKUP_DIR"
    mkdir -p "sites/$TEST_SITE_NAME/logs"
    mkdir -p "shared/config/rclone"

    # Xóa log cũ trước khi chạy test
    rm -f "$LOG_FILE"

    # Tạo tập tin `rclone.conf` giả lập
    cat <<EOL > "$RCLONE_CONFIG_FILE"
[$TEST_STORAGE]
type = drive
token = {"access_token":"fake-token","token_type":"Bearer","refresh_token":"fake-refresh-token","expiry":"2025-03-20T18:56:00.340403+07:00"}
EOL
}

# Kiểm tra backup có tạo thành công không
@test "Backup tự động tạo file backup thành công" {
    run bash "$BACKUP_SCRIPT" "$TEST_SITE_NAME" "local"
    
    # Kiểm tra xem quá trình có chạy đúng không
    [ "$status" -eq 0 ]
    
    # Kiểm tra file backup có được tạo hay không
    [ -n "$(ls -1 $BACKUP_DIR/*.sql 2>/dev/null)" ]
    [ -n "$(ls -1 $BACKUP_DIR/*.tar.gz 2>/dev/null)" ]
}

# Kiểm tra log có ghi nhận backup đúng không
@test "Log ghi nhận tiến trình backup đúng" {
    run cat "$LOG_FILE"

    # Kiểm tra log có nội dung mong muốn không
    [[ "$output" == *"✅ Bắt đầu tiến trình backup tự động cho"* ]]
    [[ "$output" == *"🔄 Đang sao lưu database..."* ]]
    [[ "$output" == *"🔄 Đang sao lưu mã nguồn..."* ]]
    [[ "$output" == *"✅ Hoàn thành backup tự động cho"* ]]
}

# Kiểm tra chọn lưu trên Storage có hoạt động không
@test "Chọn lưu trên Storage hoạt động đúng" {
    run bash "$BACKUP_SCRIPT" "$TEST_SITE_NAME" "$TEST_STORAGE"
    
    # Kiểm tra backup có chạy đúng không
    [ "$status" -eq 0 ]

    # Kiểm tra log có hiển thị thông tin lưu trên Storage không
    run cat "$LOG_FILE"
    [[ "$output" == *"☁️  Đang lưu backup lên Storage"* ]]
}

# Kiểm tra upload backup lên Storage có thành công không
@test "Upload backup lên Storage thành công" {
    # Giả lập Storage có sẵn trong rclone.conf
    echo -e "[$TEST_STORAGE]\ntype = drive" >> "$RCLONE_CONFIG_FILE"

    run bash "$BACKUP_SCRIPT" "$TEST_SITE_NAME" "$TEST_STORAGE"
    
    # Kiểm tra upload có chạy đúng không
    [ "$status" -eq 0 ]

    # Kiểm tra log có ghi nhận upload đúng không
    run cat "$LOG_FILE"
    [[ "$output" == *"📤 Bắt đầu upload backup lên Storage..."* ]]
    [[ "$output" == *"✅ Backup và upload lên Storage hoàn tất!"* ]]
}

# Kiểm tra xóa file backup sau khi upload lên Storage
@test "Xóa file backup sau khi upload lên Storage" {
    run bash "$BACKUP_SCRIPT" "$TEST_SITE_NAME" "$TEST_STORAGE"
    
    # Kiểm tra nếu file backup không còn tồn tại
    [ -z "$(ls -1 $BACKUP_DIR/*.sql 2>/dev/null)" ]
    [ -z "$(ls -1 $BACKUP_DIR/*.tar.gz 2>/dev/null)" ]
}

# Cleanup sau khi test
teardown() {
    rm -rf "$BACKUP_DIR"
    rm -f "$LOG_FILE"
}
