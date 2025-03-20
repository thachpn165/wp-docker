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

# Định nghĩa tập tin backup runner
BACKUP_RUNNER="$SCRIPTS_FUNCTIONS_DIR/backup-manager/backup_runner.sh"

# Chuyển đổi thời gian cron thành dạng dễ hiểu
cron_translate() {
    local cron_exp="$1"

    # Tách các trường cron
    local minute=$(echo "$cron_exp" | awk '{print $1}')
    local hour=$(echo "$cron_exp" | awk '{print $2}')
    local day=$(echo "$cron_exp" | awk '{print $3}')
    local month=$(echo "$cron_exp" | awk '{print $4}')
    local weekday=$(echo "$cron_exp" | awk '{print $5}')

    # Xác định thời gian
    local time="$hour:$minute"

    # Xác định tần suất
    if [[ "$day" == "*" && "$month" == "*" && "$weekday" == "*" ]]; then
        schedule="Hàng ngày vào lúc $time"
    elif [[ "$day" == "*" && "$month" == "*" && "$weekday" != "*" ]]; then
        schedule="Hàng tuần vào lúc $time, ngày $(convert_weekday "$weekday")"
    elif [[ "$day" != "*" && "$month" == "*" ]]; then
        schedule="Hàng tháng vào lúc $time, ngày $day"
    else
        schedule="Lịch tùy chỉnh: $cron_exp"
    fi

    echo "$schedule"
}

# Chuyển đổi ngày trong tuần từ số sang chữ
convert_weekday() {
    case $1 in
        0) echo "Chủ Nhật" ;;
        1) echo "Thứ Hai" ;;
        2) echo "Thứ Ba" ;;
        3) echo "Thứ Tư" ;;
        4) echo "Thứ Năm" ;;
        5) echo "Thứ Sáu" ;;
        6) echo "Thứ Bảy" ;;
        *) echo "Không xác định" ;;
    esac
}

# Hiển thị danh sách các website có lịch backup và cho phép xem chi tiết
schedule_backup_list() {
    echo -e "${BLUE}📅 Danh sách các website có lịch backup:${NC}"

    # Lấy danh sách website từ crontab
    local websites=($(crontab -l 2>/dev/null | grep "backup_runner.sh" | awk -F 'backup_runner.sh ' '{print $2}' | awk '{print $1}' | sort -u))

    if [[ ${#websites[@]} -eq 0 ]]; then
        echo -e "${RED}❌ Không có website nào có lịch backup.${NC}"
        return 1
    fi

    # Hiển thị danh sách website
    echo -e "${YELLOW}🔹 Chọn một website để xem lịch backup:${NC}"
    select SITE_NAME in "${websites[@]}"; do
        if [[ -n "$SITE_NAME" ]]; then
            echo -e "${GREEN}✅ Đang xem lịch backup của: $SITE_NAME${NC}"
            break
        else
            echo -e "${RED}❌ Lựa chọn không hợp lệ!${NC}"
        fi
    done

    # Xác định hệ điều hành (macOS hoặc Linux)
    if [[ "$(uname)" == "Darwin" ]]; then
        cron_jobs=$(crontab -l 2>/dev/null | grep "backup_runner.sh $SITE_NAME")
    else
        cron_jobs=$(crontab -l 2>/dev/null | grep "$SCRIPTS_FUNCTIONS_DIR/backup-scheduler/backup_runner.sh $SITE_NAME")
    fi

    if [[ -z "$cron_jobs" ]]; then
        echo -e "${RED}❌ Không tìm thấy lịch backup cho website: $SITE_NAME${NC}"
    else
        echo -e "${GREEN}📜 Lịch backup cho $SITE_NAME:${NC}"
        echo -e "${YELLOW}Tần suất chạy | Website | Đường dẫn lưu log${NC}"
        echo -e "${MAGENTA}------------------------------------------------------${NC}"
        
        # Dịch nghĩa thời gian chạy cron và hiển thị đầy đủ
        while IFS= read -r line; do
            cron_exp=$(echo "$line" | awk '{print $1, $2, $3, $4, $5}')
            schedule=$(cron_translate "$cron_exp")
            website=$(echo "$line" | awk -F 'backup_runner.sh ' '{print $2}' | awk '{print $1}')   # Lấy tên website chính xác
            log_path=$(echo "$line" | awk -F '>> ' '{print $2}' | awk '{print $1}')               # Lấy đường dẫn log chính xác
            
            echo -e "⏰ $schedule | 🌐 $website | 📝 $log_path"
        done <<< "$cron_jobs"

        echo -e "${MAGENTA}------------------------------------------------------${NC}"
    fi
}



# Xóa lịch backup của một website
schedule_backup_remove() {
    select_website || return

    local temp_cron=$(mktemp)
    crontab -l 2>/dev/null | grep -v "$BACKUP_RUNNER $SITE_NAME" > "$temp_cron"
    crontab "$temp_cron"
    rm -f "$temp_cron"

    echo -e "${GREEN}✅ Đã xóa lịch backup của website: $SITE_NAME${NC}"
}

# Hiển thị menu quản lý crontab
manage_cron_menu() {
    while true; do
        echo -e "${BLUE}============================${NC}"
        echo -e "${BLUE}   ⚙️ QUẢN LÝ LỊCH BACKUP (CRON)   ${NC}"
        echo -e "${BLUE}============================${NC}"
        echo -e "  ${GREEN}[1]${NC} 📜 Xem danh sách lịch backup"
        echo -e "  ${GREEN}[2]${NC} ❌ Xóa lịch backup của một website"
        echo -e "  ${GREEN}[3]${NC} 🔙 Quay lại"
        echo -e "${BLUE}============================${NC}"

        read -p "🔹 Chọn một tùy chọn (1-3): " choice
        case "$choice" in
            1) schedule_backup_list ;;
            2) schedule_backup_remove ;;
            3) echo -e "${GREEN}🔙 Quay lại menu chính.${NC}"; break ;;
            *) echo -e "${RED}❌ Lựa chọn không hợp lệ, vui lòng nhập lại!${NC}" ;;
        esac
    done
}

# Kiểm tra xem một website đã có lịch backup chưa
schedule_backup_exists() {
    local site_name="$1"

    # Kiểm tra trong crontab có backup_runner.sh cho website đó không
    if crontab -l 2>/dev/null | grep -q "backup_runner.sh $site_name"; then
        return 0  # Đã có lịch backup
    else
        return 1  # Chưa có lịch backup
    fi
}