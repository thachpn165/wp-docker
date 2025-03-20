#!/bin/bash

CONFIG_FILE="shared/config/config.sh"

# Xác định đường dẫn tuyệt đối của `config.sh`
while [ ! -f "$CONFIG_FILE" ]; do
    CONFIG_FILE="../$CONFIG_FILE"
    if [ "$(pwd)" = "/" ]; then
        echo "❌ Lỗi: Không tìm thấy config.sh!" >&2
        exit 1
    fi
done

source "$CONFIG_FILE"

# Hàm lên lịch backup
schedule_backup_create() {
    select_website || return

    local log_dir="$SITES_DIR/$SITE_NAME/logs"
    local log_file="$log_dir/wp-backup.log"
    local cron_job=""
    local backup_script="$SCRIPTS_FUNCTIONS_DIR/backup-scheduler/backup_runner.sh"

    is_directory_exist "$log_dir"

    # Hỏi người dùng muốn lưu backup vào Local hay Storage
    echo -e "${BLUE}📂 Chọn nơi lưu backup tự động:${NC}"
    echo -e "  ${GREEN}[1]${NC} 💾 Lưu vào máy chủ (local)"
    echo -e "  ${GREEN}[2]${NC} ☁️  Lưu vào Storage đã thiết lập"
    read -p "🔹 Chọn một tùy chọn (1-2): " storage_choice

    local storage_option="local"
    local selected_storage=""

    if [[ "$storage_choice" == "2" ]]; then
        echo -e "${BLUE}📂 Đang lấy danh sách Storage từ rclone.conf...${NC}"
        
        # Gọi `rclone_storage_list()` để lấy danh sách Storage
        local storages=()
        while IFS= read -r line; do
            storages+=("$line")
        done < <(rclone_storage_list)

        if [[ ${#storages[@]} -eq 0 ]]; then
            echo -e "${RED}❌ Không có Storage nào được thiết lập trong rclone.conf!${NC}"
            return 1
        fi

        # Hiển thị danh sách Storage rõ ràng
        echo -e "${BLUE}📂 Danh sách Storage khả dụng:${NC}"
        for storage in "${storages[@]}"; do
            echo -e "  ${GREEN}➜${NC} ${CYAN}$storage${NC}"
        done

        echo -e "${YELLOW}💡 Hãy nhập chính xác tên Storage từ danh sách trên.${NC}"
        while true; do
            read -p "🔹 Nhập tên Storage để sử dụng: " selected_storage
            selected_storage=$(echo "$selected_storage" | xargs)  # Loại bỏ khoảng trắng thừa

            # Kiểm tra nếu storage tồn tại trong danh sách
            if [[ " ${storages[*]} " =~ " ${selected_storage} " ]]; then
                echo -e "${GREEN}☁️  Đã chọn Storage: '$selected_storage'${NC}"
                storage_option="$selected_storage"
                break
            else
                echo -e "${RED}❌ Storage không hợp lệ! Vui lòng nhập đúng tên Storage.${NC}"
            fi
        done
    fi

    echo -e "${BLUE}📅 Chọn thời gian chạy backup tự động:${NC}"
    echo -e "  ${GREEN}[1]${NC} Hàng ngày (02:00 sáng)"
    echo -e "  ${GREEN}[2]${NC} Hàng tuần (Chủ nhật lúc 03:00 sáng)"
    echo -e "  ${GREEN}[3]${NC} Hàng tháng (Ngày 1 lúc 04:00 sáng)"
    echo -e "  ${GREEN}[4]${NC} Tùy chỉnh thời gian"
    echo -e "  ${GREEN}[5]${NC} Thoát"
    echo ""

    read -p "🔹 Chọn một tùy chọn (1-5): " choice

    case "$choice" in
        1) cron_job="0 2 * * * bash $backup_script $SITE_NAME $storage_option >> $log_file 2>&1" ;;
        2) cron_job="0 3 * * 0 bash $backup_script $SITE_NAME $storage_option >> $log_file 2>&1" ;;
        3) cron_job="0 4 1 * * bash $backup_script $SITE_NAME $storage_option >> $log_file 2>&1" ;;
        4) 
            read -p "🔹 Nhập lịch chạy theo cú pháp crontab (VD: '30 2 * * *'): " custom_cron
            cron_job="$custom_cron bash $backup_script $SITE_NAME $storage_option >> $log_file 2>&1"
            ;;
        5) 
            echo -e "${GREEN}❌ Thoát khỏi cài đặt lịch backup.${NC}"
            return
            ;;
        *) 
            echo -e "${RED}❌ Lựa chọn không hợp lệ!${NC}"
            return
            ;;
    esac

    # Thêm cron job vào crontab
    (crontab -l 2>/dev/null | grep -v "$backup_script $SITE_NAME"; echo "$cron_job") | crontab -

    echo -e "${GREEN}✅ Lịch backup đã được thiết lập thành công!${NC}"
}
