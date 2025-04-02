backup_database_logic() {
    local site_name="$1"
    local db_name="$2"
    local db_user="$3"
    local db_pass="$4"
    local container_name="${site_name}-mariadb"
    local backup_filename="db-${site_name}-$(date +%Y%m%d-%H%M%S).sql"
    local backup_path="$SITES_DIR/$site_name/backups/${backup_filename}"

    
    is_directory_exist "$SITES_DIR/$site_name/backups"
    is_directory_exist "$SITES_DIR/$site_name/logs"
    
    # Check MariaDB container status before backup
    if ! docker ps --filter "name=${container_name}" --filter "status=running" | grep -q "${container_name}"; then
        echo "${CROSSMARK} The container ${container_name} is not running. Backup cannot proceed."
        return 1
    fi

    echo "🔹 Backing up database for ${site_name} in container ${container_name}..."

    # Perform database backup inside container and save to /backups/
    docker exec -e MYSQL_PWD="${db_pass}" "${container_name}" \
        mysqldump --skip-lock-tables -u "${db_user}" "${db_name}" > "${backup_path}"

    # Check result and return file path
    if [[ $? -eq 0 ]]; then
        echo "${CHECKMARK} Database backup successful: $backup_path"
        echo -n "$backup_path"  # Return only the path, no log
    else
        echo "${CROSSMARK} Error during database backup!"
        return 1
    fi
}
