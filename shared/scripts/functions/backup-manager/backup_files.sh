backup_files() {
    local site_name="$1"
    local web_root="$2"
    local backup_dir="$SITES_DIR/${site_name}/backups"
    local backup_file="${backup_dir}/files-${site_name}-$(date +%Y%m%d-%H%M%S).tar.gz"

    is_directory_exist "$backup_dir" || return 1

    echo "🔹 Đang sao lưu file của ${site_name}..."
    tar -czf "${backup_file}" -C "${web_root}" . 2>/dev/null

    if [[ $? -eq 0 ]]; then
        echo "✅ File WordPress được sao lưu thành công: ${backup_file}"
        echo -n "$backup_file"  # Chỉ trả về đường dẫn, không có log
    else
        echo "❌ Lỗi khi sao lưu file!"
        return 1
    fi
}
