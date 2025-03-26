#!/bin/bash

cleanup_backups() {
    local site_name="$1"
    local retention_days="$2"
    local backup_dir="$SITES_DIR/${site_name}/backups"
    local deleted_files=()

    if [[ ! -d "$backup_dir" ]]; then
        echo "❌ Không tìm thấy thư mục backup cho $site_name!"
        return 1
    fi

    echo "🗑️ Đang kiểm tra và xóa các bản sao lưu cũ hơn ${retention_days} ngày..."

    # Tìm và lưu danh sách file sẽ bị xóa
    while IFS= read -r file; do
        deleted_files+=("$file")
    done < <(find "$backup_dir" -type f \( -name "*.tar.gz" -o -name "*.sql" \) -mtime +$retention_days)

    # Xóa file nếu có
    if [[ ${#deleted_files[@]} -gt 0 ]]; then
        for file in "${deleted_files[@]}"; do
            rm -f "$file"
            echo "🗑️ Đã xóa: $file"
        done
        echo "✅ Hoàn thành dọn dẹp backup của $site_name."
    else
        echo "ℹ️ Không có backup nào bị xóa. Tất cả bản sao lưu đều trong giới hạn ${retention_days} ngày."
    fi
}
