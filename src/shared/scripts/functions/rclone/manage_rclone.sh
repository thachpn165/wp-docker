# Function to display list of configured storages
rclone_storage_list() {
    local rclone_config=$BASE_DIR/$RCLONE_CONFIG_FILE

    if ! is_file_exist "$rclone_config"; then
        echo -e "${RED}❌ Rclone configuration file not found.${NC}"
        return 1
    fi

    # Get list of storages from `rclone.conf` (works on both macOS & Linux)
    sed -n 's/^\[\(.*\)\]$/\1/p' "$rclone_config"
}

# Function to delete configured storage
rclone_storage_delete() {
    local rclone_config=$RCLONE_CONFIG_FILE


    if ! is_file_exist "$rclone_config"; then
        echo -e "${RED}❌ Rclone configuration file not found.${NC}"
        return 1
    fi

    local storages=($(grep '^\[' "$rclone_config" | tr -d '[]'))

    if [[ ${#storages[@]} -eq 0 ]]; then
        echo -e "${RED}❌ No storages available to delete.${NC}"
        return 1
    fi

    echo -e "${BLUE}📂 Select storage to delete:${NC}"
    select storage in "${storages[@]}"; do
        if [[ -n "$storage" ]]; then
            sed -i "/^\[$storage\]/,/^$/d" "$rclone_config"
            echo -e "${GREEN}✅ Storage '$storage' has been removed from configuration.${NC}"
            break
        else
            echo -e "${RED}❌ Invalid selection.${NC}"
        fi
    done
}