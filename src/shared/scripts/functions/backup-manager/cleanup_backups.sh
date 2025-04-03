#!/bin/bash

cleanup_backups() {
    local domain="$1"
    local retention_days="$2"
    local backup_dir="$SITES_DIR/${domain}/backups"
    local deleted_files=()

    if [[ ! -d "$backup_dir" ]]; then
        echo "${CROSSMARK} Backup directory not found for $domain!"
        return 1
    fi

    echo "🗑️ Checking and deleting backups older than ${retention_days} days..."

    # Find and save list of files to be deleted
    while IFS= read -r file; do
        deleted_files+=("$file")
    done < <(find "$backup_dir" -type f \( -name "*.tar.gz" -o -name "*.sql" \) -mtime +$retention_days)

    # Delete files if any exist
    if [[ ${#deleted_files[@]} -gt 0 ]]; then
        for file in "${deleted_files[@]}"; do
            rm -f "$file"
            echo "🗑️ Deleted: $file"
        done
        echo "${CHECKMARK} Cleanup completed for $domain backups."
    else
        echo "${INFO} No backups were deleted. All backups are within the ${retention_days} days limit."
    fi
}
