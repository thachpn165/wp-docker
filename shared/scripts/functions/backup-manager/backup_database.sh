backup_database() {
    local site_name="$1"
    local db_name="$2"
    local db_user="$3"
    local db_pass="$4"
    local container_name="${site_name}-mariadb"
    local backup_filename="db-${site_name}-$(date +%Y%m%d-%H%M%S).sql"
    local backup_path="$SITES_DIR/$site_name/backups/${backup_filename}"

    #Debug
    echo "📦 DEBUG: site_name=$site_name, db_name=$db_name, db_user=$db_user"

    is_directory_exist "$SITES_DIR/$site_name/backups"
    is_directory_exist "$SITES_DIR/$site_name/logs"
    

    echo "🔹 Đang sao lưu database của ${site_name} trong container ${container_name}..."

    # Thực hiện backup database bên trong container và lưu vào /backups/
    docker exec -e MYSQL_PWD="${db_pass}" "${container_name}" \
        mysqldump --skip-lock-tables -u "${db_user}" "${db_name}" > "${backup_path}"

    # Kiểm tra kết quả và trả về đường dẫn tập tin
    if [[ $? -eq 0 ]]; then
        echo "✅ Database được sao lưu thành công: $backup_path"
        echo -n "$backup_path"  # Chỉ trả về đường dẫn, không có log
    else
        echo "❌ Lỗi khi sao lưu database!"
        return 1
    fi
}
