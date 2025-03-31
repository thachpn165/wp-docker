# backup_manage: Quản lý backup, có thể liệt kê hoặc xóa các backup cũ dựa trên tham số
backup_manage() {
    local site_name="$1"
    local backup_dir="$SITES_DIR/$site_name/backups"
    local action="$2"
    local max_age_days="${3:-7}" 

    # Kiểm tra thư mục backup tồn tại
    if [[ ! -d "$backup_dir" ]]; then
        echo "❌ Directory $backup_dir not found!"
        return 1
    fi

    case "$action" in
        "list")
            # Liệt kê các file backup
            echo "Listing backups for $site_name in $backup_dir:"

            # Determine operating system (macOS or Linux)
            if [[ "$(uname)" == "Darwin" ]]; then
                FIND_CMD="ls -lt $backup_dir | awk '{print \$6, \$7, \$8, \$9}'"
            else
                FIND_CMD="find $backup_dir -type f -printf '%TY-%Tm-%Td %TH:%TM %p\n' | sort -r"
            fi

            # Liệt kê FILE BACKUP (tập tin .tar.gz)
            echo -e "${YELLOW}📂 FILE BACKUP (tar.gz files):${NC}"
            eval $FIND_CMD | grep ".tar.gz"
            if [[ $? -eq 0 ]]; then
                echo "✅ File backup listing completed."
            else
                echo "❌ Error listing file backups."
            fi
            
            # Liệt kê DATABASE BACKUP (tập tin .sql)
            echo -e "${YELLOW}📂 DATABASE BACKUP (sql files):${NC}"
            eval $FIND_CMD | grep ".sql"
            if [[ $? -eq 0 ]]; then
                echo "✅ Database backup listing completed."
            else
                echo "❌ Error listing database backups."
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