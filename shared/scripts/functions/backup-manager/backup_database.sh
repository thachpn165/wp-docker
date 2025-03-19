source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/utils.sh"

backup_database() {
    local site_name="$1"
    local db_name="$2"
    local db_user="$3"
    local db_pass="$4"
    local container_name="${site_name}-mariadb"
    local backup_filename="db-${site_name}-$(date +%Y%m%d-%H%M%S).sql"
    local container_backup_path="$SITES_DIR/$site_name/backups/${backup_filename}"

    echo "$container_name";
    # Đảm bảo thư mục backup tồn tại

    echo "🔹 Đang sao lưu database của ${site_name} trong container ${container_name}..."

    # Thực hiện backup database bên trong container và lưu vào /backups/
    docker exec -e MYSQL_PWD="${db_pass}" "${container_name}" \
        mysqldump --skip-lock-tables -u "${db_user}" "${db_name}" > "${container_backup_path}"

    # Kiểm tra kết quả
    if [[ $? -eq 0 ]]; then
        echo "✅ Database được sao lưu thành công: sites/${site_name}/backups/${backup_filename}"
    else
        echo "❌ Lỗi khi sao lưu database!"
    fi
}

