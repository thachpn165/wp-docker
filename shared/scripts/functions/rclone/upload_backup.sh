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

RCLONE_CONFIG_FILE="shared/config/rclone/rclone.conf"

is_file_exist "$RCLONE_CONFIG_FILE" || { echo -e "${RED}❌ Lỗi: Không tìm thấy tập tin cấu hình Rclone! Hãy thực hiện cấu hình Rclone trước.${NC}"; exit 1; }

# Kiểm tra nếu `dialog` chưa được cài đặt, tự động cài đặt
if ! command -v dialog &> /dev/null; then
    echo -e "${YELLOW}⚠️ Dialog chưa được cài đặt. Tiến hành cài đặt...${NC}"
    
    if [[ "$(uname)" == "Darwin" ]]; then
        brew install dialog || { echo -e "${RED}❌ Lỗi: Cài đặt dialog thất bại!${NC}"; exit 1; }
    elif [[ -f /etc/debian_version ]]; then
        sudo apt update && sudo apt install dialog -y || { echo -e "${RED}❌ Lỗi: Cài đặt dialog thất bại!${NC}"; exit 1; }
    elif [[ -f /etc/redhat-release ]]; then
        sudo yum install dialog -y || { echo -e "${RED}❌ Lỗi: Cài đặt dialog thất bại!${NC}"; exit 1; }
    else
        echo -e "${RED}❌ Hệ điều hành không được hỗ trợ tự động cài đặt dialog. Vui lòng cài đặt thủ công.${NC}"
        exit 1
    fi

    echo -e "${GREEN}✅ Cài đặt dialog thành công!${NC}"
fi

# Hàm hiển thị danh sách tập tin backup và cho phép chọn nhiều tập tin
select_backup_files() {
    local backup_dir="$1"
    local choice_list=()
    local selected_files=()

    # Kiểm tra thư mục backup có tồn tại không
    if ! is_directory_exist "$backup_dir"; then
        echo -e "${RED}❌ Không tìm thấy thư mục backup: $backup_dir${NC}"
        return 1
    fi

    # Lấy danh sách các tập tin backup
    local backup_files=($(ls -1 "$backup_dir"))

    if [[ ${#backup_files[@]} -eq 0 ]]; then
        echo -e "${RED}❌ Không tìm thấy tập tin backup trong $backup_dir${NC}"
        return 1
    fi

    # Tạo danh sách file cho `dialog`
    for file in "${backup_files[@]}"; do
        choice_list+=("$file" "$file" "off")
    done

    # Hiển thị `dialog` để chọn file
    selected_files=$(dialog --stdout --separate-output --checklist "Chọn tập tin backup để upload bằng phím Spacebar, xác nhận bằng Enter:" 15 60 10 "${choice_list[@]}")

    # Nếu không chọn file nào, upload tất cả
    if [[ -z "$selected_files" ]]; then
        selected_files=("${backup_files[@]}")
    else
        # Chuyển đổi chuỗi thành mảng đúng cách
        IFS=$'\n' read -r -d '' -a selected_files <<< "$(echo "$selected_files" | tr -d '\r')"
    fi

    echo "${selected_files[@]}"
}

# Hàm upload backup
upload_backup() {
    select_website || return

    local storage="${1:-default}"  # Nếu không có tham số, dùng storage mặc định
    local backup_dir="$SITES_DIR/$SITE_NAME/backups"
    local log_dir="$SITES_DIR/$SITE_NAME/logs"
    local log_file="$log_dir/rclone-upload.log"

    is_directory_exist "$log_dir"

    # Nếu có tham số file backup, dùng ngay
    if [[ $# -gt 1 ]]; then
        local selected_files=("${@:2}")  # Lấy danh sách file từ tham số truyền vào
    else
        # Hiển thị danh sách tập tin backup và cho phép chọn
        local selected_files=($(select_backup_files "$backup_dir"))
    fi

    if [[ ${#selected_files[@]} -eq 0 ]]; then
        echo -e "${RED}❌ Không có tập tin backup nào được chọn để upload.${NC}" | tee -a "$log_file"
        return 1
    fi

    echo -e "${BLUE}📤 Đang upload các tập tin backup lên storage ($storage)...${NC}" | tee -a "$log_file"

    # Upload từng tập tin đã chọn
    for file in "${selected_files[@]}"; do
        echo -e "${YELLOW}🚀 Uploading: $file${NC}" | tee -a "$log_file"
        rclone --config "$RCLONE_CONFIG_FILE" copy "$backup_dir/$file" "$storage:backup-folder" \
            --progress --log-file "$log_file"

        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}✅ Upload thành công: $file${NC}" | tee -a "$log_file"
        else
            echo -e "${RED}❌ Upload thất bại: $file${NC}" | tee -a "$log_file"
        fi
    done

    echo -e "${GREEN}📤 Hoàn tất quá trình upload backup lên storage!${NC}" | tee -a "$log_file"
}

upload_backup "$@"
