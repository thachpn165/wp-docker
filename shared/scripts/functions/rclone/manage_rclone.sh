# Hàm hiển thị danh sách storage đã thiết lập
rclone_storage_list() {
    local rclone_config="shared/config/rclone/rclone.conf"

    if ! is_file_exist "$rclone_config"; then
        echo -e "${RED}❌ Không tìm thấy tập tin cấu hình Rclone.${NC}"
        return 1
    fi

    # Lấy danh sách storage từ `rclone.conf` (hoạt động trên cả macOS & Linux)
    sed -n 's/^\[\(.*\)\]$/\1/p' "$rclone_config"
}



# Hàm xóa storage đã thiết lập
rclone_storage_delete() {
    local rclone_config="shared/config/rclone/rclone.conf"

    if ! is_file_exist "$rclone_config"; then
        echo -e "${RED}❌ Không tìm thấy tập tin cấu hình Rclone.${NC}"
        return 1
    fi

    local storages=($(grep '^\[' "$rclone_config" | tr -d '[]'))

    if [[ ${#storages[@]} -eq 0 ]]; then
        echo -e "${RED}❌ Không có storage nào để xóa.${NC}"
        return 1
    fi

    echo -e "${BLUE}📂 Chọn storage để xóa:${NC}"
    select storage in "${storages[@]}"; do
        if [[ -n "$storage" ]]; then
            sed -i "/^\[$storage\]/,/^$/d" "$rclone_config"
            echo -e "${GREEN}✅ Storage '$storage' đã được xóa khỏi cấu hình.${NC}"
            break
        else
            echo -e "${RED}❌ Lựa chọn không hợp lệ.${NC}"
        fi
    done
}