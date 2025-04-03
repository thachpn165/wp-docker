backup_file_logic() {
    local domain="$1"
    local web_root="$SITES_DIR/${domain}/wordpress"  # Automatically determine web root
    local backup_dir="$SITES_DIR/${domain}/backups"
    local backup_file="${backup_dir}/files-${domain}-$(date +%Y%m%d-%H%M%S).tar.gz"

    is_directory_exist "$SITES_DIR/$domain/backups"
    is_directory_exist "$SITES_DIR/$domain/logs"

    echo "🔹 Backing up files for ${domain}..."
    tar -czf "${backup_file}" -C "${web_root}" . 2>/dev/null

    if [[ $? -eq 0 ]]; then
        echo "${CHECKMARK} WordPress files backup successful: ${backup_file}"
        echo -n "$backup_file"  # Return only the path, no log
    else
        echo "${CROSSMARK} Error during file backup!"
        return 1
    fi
}
