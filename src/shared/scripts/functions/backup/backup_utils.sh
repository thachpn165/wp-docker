# backup_manage: Quản lý backup, có thể liệt kê hoặc xóa các backup cũ dựa trên tham số
backup_manage() {
    local site_name="$1"
    local backup_dir="$SITES_DIR/$site_name/backups"
    local action="$2"
    local max_age_days="$3"

    # Kiểm tra thư mục backup tồn tại
    if [[ ! -d "$backup_dir" ]]; then
        echo "❌ Directory $backup_dir not found!"
        return 1
    fi

    case "$action" in
        "list")
            # Liệt kê các file backup
            echo "Listing backups for $site_name in $backup_dir:"
            find "$backup_dir" -type f -name "*.tar.gz" -print
            if [[ $? -eq 0 ]]; then
                echo "✅ Backup listing completed."
            else
                echo "❌ Error listing backups."
                return 1
            fi
            ;;
        "clean")
            # Xóa các file backup cũ
            echo "Cleaning old backups older than $max_age_days days in $backup_dir"
            find "$backup_dir" -type f -name "*.tar.gz" -mtime +$max_age_days -exec rm -f {} \;
            if [[ $? -eq 0 ]]; then
                echo "✅ Old backups older than $max_age_days days have been removed from $backup_dir."
            else
                echo "❌ Error removing old backups."
                return 1
            fi
            ;;
        *)
            echo "❌ Invalid action: $action. Use 'list' or 'clean'."
            return 1
            ;;
    esac
}