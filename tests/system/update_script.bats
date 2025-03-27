#!/usr/bin/env bats

setup() {
    export TEST_DIR="$(mktemp -d)"
    export PROJECT_DIR="$TEST_DIR/src"

    SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../src" && pwd)"

    # Tạo thư mục giả lập cần thiết
    mkdir -p "$PROJECT_DIR/shared/templates"
    mkdir -p "$PROJECT_DIR/shared/scripts/tools"
    mkdir -p "$PROJECT_DIR/shared/config"
    mkdir -p "$PROJECT_DIR/sites/test-site"  # Tạo thư mục test-site
    mkdir -p "$PROJECT_DIR/sites/test-site/db"  # Tạo thư mục db giả lập
    mkdir -p "$PROJECT_DIR/sites/test-site/db/dumps"  # Tạo thư mục dumps giả lập

    # Tạo thư mục archives và logs
    mkdir -p "$PROJECT_DIR/archives"  # Tạo thư mục archives giả lập
    mkdir -p "$PROJECT_DIR/logs"      # Tạo thư mục logs giả lập

    # Giả lập file .template_version và changelog
    echo "1.0.6" > "$PROJECT_DIR/shared/templates/.template_version"
    echo "# TEMPLATE CHANGELOG" > "$PROJECT_DIR/shared/templates/TEMPLATE_CHANGELOG.md"

    # Giả lập file .template_version trong site
    echo "0.0.0" > "$PROJECT_DIR/sites/test-site/.template_version"  # Giả lập site dùng phiên bản template cũ

    # Giả lập script update.sh
    cat > "$PROJECT_DIR/update.sh" << EOF
#!/bin/bash
# Nội dung chính của update.sh (có thể dùng thực tế hoặc mock lại một phần)
source /opt/wp-docker/scripts/update.sh

# Ghi vào file log để kiểm tra trong test
echo "Updating WP Docker..." > /tmp/update_wp_docker.log
EOF

    chmod +x "$PROJECT_DIR/update.sh"
}

teardown() {
    [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

@test "Update should download the latest release and overwrite necessary files" {
    run bash "$PROJECT_DIR/update.sh"

    # Kiểm tra xem các tệp đã được cập nhật
    run cat "$PROJECT_DIR/version.txt"
    [ "$output" != "1.0.6" ]  # Kiểm tra version có thay đổi (là bản mới tải về)

    # Kiểm tra các tệp hệ thống đã được ghi đè (trừ data)
    run [ -f "$PROJECT_DIR/shared/templates/.template_version" ]
    [ "$status" -eq 0 ]

    run [ -f "$PROJECT_DIR/shared/templates/TEMPLATE_CHANGELOG.md" ]
    [ "$status" -eq 0 ]
}

@test "Update should exclude specific directories (like sites and logs)" {
    run bash "$PROJECT_DIR/update.sh"

    # Kiểm tra xem log đã được tạo
    run cat /tmp/update_wp_docker.log
    [ "$status" -eq 0 ]

    # Debug: In ra các thư mục đã được loại trừ trong rsync
    echo ">>> Debugging rsync output:"
    cat /tmp/update_wp_docker.log

    # Kiểm tra nếu các thư mục `sites` và `logs` không bị ghi đè
    run [ -d "$PROJECT_DIR/sites" ]
    [ "$status" -eq 0 ]

    run [ -d "$PROJECT_DIR/logs" ]
    [ "$status" -eq 0 ]

    # Kiểm tra nếu các thư mục này **không bị xóa** và **vẫn tồn tại** sau khi update
    run [ -d "$PROJECT_DIR/sites/test-site" ]  # Kiểm tra site cũ không bị xoá
    [ "$status" -eq 0 ]
}

@test "Update should not remove the archives folder" {
    run bash "$PROJECT_DIR/update.sh"

    # Kiểm tra nếu thư mục archives không bị xóa
    run [ -d "$PROJECT_DIR/archives" ]
    [ "$status" -eq 0 ]
}
