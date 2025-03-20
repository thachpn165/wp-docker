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
source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/backup_actions.sh"

# Hàm lên lịch backup
schedule_backup_create() {
    select_website || return

    # Kiểm tra nếu website đã có lịch backup
    if schedule_backup_exists "$SITE_NAME"; then
        echo -e "${RED}❌ Website $SITE_NAME đã có lịch backup!${NC}"
        return 1
    fi

    local log_dir="$SITES_DIR/$SITE_NAME/logs"
    local log_file="$log_dir/wp-backup.log"
    local cron_job=""
    local backup_script="$SCRIPTS_FUNCTIONS_DIR/backup-scheduler/backup_runner.sh"

    is_directory_exist "$log_dir"

    echo -e "${BLUE}📅 Chọn thời gian chạy backup tự động:${NC}"
    echo -e "  ${GREEN}[1]${NC} Hàng ngày (02:00 sáng)"
    echo -e "  ${GREEN}[2]${NC} Hàng tuần (Chủ nhật lúc 03:00 sáng)"
    echo -e "  ${GREEN}[3]${NC} Hàng tháng (Ngày 1 lúc 04:00 sáng)"
    echo -e "  ${GREEN}[4]${NC} Tùy chỉnh thời gian"
    echo -e "  ${GREEN}[5]${NC} Thoát"
    echo ""

    read -p "🔹 Chọn một tùy chọn (1-5): " choice

    case "$choice" in
        1) cron_job="0 2 * * * bash $backup_script $SITE_NAME >> $log_file 2>&1" ;;
        2) cron_job="0 3 * * 0 bash $backup_script $SITE_NAME >> $log_file 2>&1" ;;
        3) cron_job="0 4 1 * * bash $backup_script $SITE_NAME >> $log_file 2>&1" ;;
        4) 
            read -p "🔹 Nhập lịch chạy theo cú pháp crontab (VD: '30 2 * * *'): " custom_cron
            cron_job="$custom_cron bash $backup_script $SITE_NAME >> $log_file 2>&1"
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

