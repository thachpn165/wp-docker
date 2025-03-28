#!/bin/bash

CONFIG_FILE="shared/config/config.sh"

while [ ! -f "$CONFIG_FILE" ]; do
    CONFIG_FILE="../$CONFIG_FILE"
    if [ "$(pwd)" = "/" ]; then
        echo "❌ Error: config.sh not found!" >&2
        exit 1
    fi
done

source "$CONFIG_FILE"

RCLONE_CONFIG_FILE="shared/config/rclone/rclone.conf"

select_backup_files() {
    local backup_dir="$1"
    local choice_list=()
    local selected_files=()

    if ! is_directory_exist "$backup_dir"; then
        echo -e "${RED}❌ Backup directory not found: $backup_dir${NC}"
        return 1
    fi

    local backup_files=($(ls -1 "$backup_dir" 2>/dev/null))

    if [[ ${#backup_files[@]} -eq 0 ]]; then
        echo -e "${RED}❌ No backup files found in $backup_dir${NC}"
        return 1
    fi

    for file in "${backup_files[@]}"; do
        choice_list+=("$file" "$file" "off")
    done

    selected_files=$(dialog --stdout --separate-output --checklist "Select backup files to upload using Spacebar, confirm with Enter:" 15 60 10 "${choice_list[@]}")

    if [[ -z "$selected_files" ]]; then
        selected_files=("${backup_files[@]}")
    else
        IFS=$'\n' read -r -d '' -a selected_files <<< "$(echo "$selected_files" | tr -d '\r')"
    fi

    echo "${selected_files[@]}"
}

upload_backup() {
    echo -e "${BLUE}📤 Starting backup upload...${NC}"

    if [[ $# -lt 1 ]]; then
        echo -e "${RED}❌ Missing storage parameter!${NC}"
        echo -e "📌 Usage: upload_backup <storage> [file1 file2 ...]"
        return 1
    fi

    local storage="$1"
    shift

    # If no files are passed, ask user to select
    local selected_files=()
    if [[ $# -eq 0 ]]; then
        echo -e "${BLUE}📂 No files passed. Will display selection list...${NC}"

        # Find the nearest site_name with backups directory
        local found_dir=$(find "$SITES_DIR" -type d -name backups | head -n1)
        if [[ -z "$found_dir" ]]; then
            echo -e "${RED}❌ No backups directory found in any site!${NC}"
            return 1
        fi

        selected_files=($(select_backup_files "$found_dir"))

        if [[ ${#selected_files[@]} -eq 0 ]]; then
            echo -e "${RED}❌ No files selected for upload.${NC}"
            return 1
        fi

        # selected_files contains file names, add full path
        for i in "${!selected_files[@]}"; do
            selected_files[$i]="$found_dir/${selected_files[$i]}"
        done
    else
        selected_files=("$@")
    fi

    local first_file="${selected_files[0]}"
    local site_name=$(echo "$first_file" | awk -F '/' '{for(i=1;i<=NF;i++) if($i=="sites") print $(i+1)}')

    if [[ -z "$site_name" ]]; then
        echo -e "${RED}❌ Cannot determine site from file: $first_file${NC}"
        return 1
    fi

    local log_file="$SITES_DIR/$site_name/logs/rclone-upload.log"
    mkdir -p "$(dirname "$log_file")"

    echo -e "${BLUE}📂 Files to be uploaded:${NC}" | tee -a "$log_file"
    for file in "${selected_files[@]}"; do
        echo "   ➜ $file" | tee -a "$log_file"
    done

    if ! is_file_exist "$RCLONE_CONFIG_FILE"; then
        echo -e "${RED}❌ Rclone configuration not found!${NC}" | tee -a "$log_file"
        return 1
    fi

    for file in "${selected_files[@]}"; do
        echo -e "${YELLOW}🚀 Uploading: $file${NC}" | tee -a "$log_file"
        rclone --config "$RCLONE_CONFIG_FILE" copy "$file" "$storage:backup-folder" \
            --progress --log-file "$log_file"

        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}✅ Upload successful: $file${NC}" | tee -a "$log_file"
        else
            echo -e "${RED}❌ Upload failed: $file${NC}" | tee -a "$log_file"
        fi
    done

    echo -e "${GREEN}📤 Upload completed!${NC}" | tee -a "$log_file"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    upload_backup "$@"
fi
