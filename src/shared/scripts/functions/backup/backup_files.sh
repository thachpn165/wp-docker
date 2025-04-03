backup_file_logic() {
    local site_name="$1"
    local web_root="$SITES_DIR/${site_name}/wordpress"  # Automatically determine web root
    local backup_dir="$SITES_DIR/${site_name}/backups"
    local backup_file="${backup_dir}/files-${site_name}-$(date +%Y%m%d-%H%M%S).tar.gz"

    is_directory_exist "$SITES_DIR/$site_name/backups"
    is_directory_exist "$SITES_DIR/$site_name/logs"

    echo "🔹 Backing up files for ${site_name}..."
    tar -czf "${backup_file}" -C "${web_root}" . 2>/dev/null

    if [[ $? -eq 0 ]]; then
        echo "${CHECKMARK} WordPress files backup successful: ${backup_file}"
        echo -n "$backup_file"  # Return only the path, no log
    else
        echo "${CROSSMARK} Error during file backup!"
        return 1
    fi
}
