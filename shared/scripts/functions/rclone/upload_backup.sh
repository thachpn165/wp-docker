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

is_file_exist "$RCLONE_CONFIG_FILE" || { echo -e "${RED}❌ Lỗi: Không tìm thấy tập tin cấu hình Rclone!${NC}"; exit 1; }

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

is_file_exist "$RCLONE_CONFIG_FILE" || { echo -e "${RED}❌ Lỗi: Không tìm thấy tập tin cấu hình Rclone!${NC}"; exit 1; }

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

is_file_exist "$RCLONE_CONFIG_FILE" || { echo -e "${RED}❌ Lỗi: Không tìm thấy tập tin cấu hình Rclone!${NC}"; exit 1; }

upload_backup() {
    echo -e "${BLUE}📤 Bắt đầu upload backup...${NC}"

    if [[ $# -lt 1 ]]; then
        echo -e "${RED}❌ Lỗi: Thiếu tham số storage!${NC}"
        echo -e "📌 Cách sử dụng: $0 <storage> [file1] [file2] ..."
        return 1
    fi

    local storage="$1"
    shift
    local first_file="${1:-}"
    
    # Lấy site_name từ đường dẫn file backup (dự đoán từ thư mục chứa file)
    local site_name=""
    if [[ -n "$first_file" ]]; then
        site_name=$(basename "$(dirname "$(dirname "$first_file")")")
    fi

    if [[ -z "$site_name" ]]; then
        echo -e "${RED}❌ Lỗi: Không thể xác định site_name từ đường dẫn file backup!${NC}"
        return 1
    fi

    local log_dir="$SITES_DIR/$site_name/logs"
    local log_file="$log_dir/rclone-upload.log"

    is_directory_exist "$log_dir"

    # Nếu không có tham số file backup, hỏi chọn file
    local selected_files=()
    if [[ $# -eq 0 ]]; then
        echo -e "${BLUE}📂 Không có tập tin backup nào được truyền vào. Hiển thị hộp thoại chọn file...${NC}"
        selected_files=($(select_backup_files "$SITES_DIR/$site_name/backups"))
    else
        selected_files=("$@")
    fi

    # Kiểm tra danh sách file trước khi upload
    if [[ ${#selected_files[@]} -eq 0 ]]; then
        echo -e "${RED}❌ Không có tập tin hợp lệ để upload.${NC}" | tee -a "$log_file"
        return 1
    fi

    echo -e "${BLUE}📂 Danh sách file sẽ upload:${NC}" | tee -a "$log_file"
    for file in "${selected_files[@]}"; do
        echo "   ➜ $file" | tee -a "$log_file"
    done

    # Upload từng tập tin đã chọn
    for file in "${selected_files[@]}"; do
        echo -e "${YELLOW}🚀 Uploading: $file${NC}" | tee -a "$log_file"

        rclone --config "$RCLONE_CONFIG_FILE" copy "$file" "$storage:backup-folder" \
            --progress --log-file "$log_file"

        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}✅ Upload thành công: $file${NC}" | tee -a "$log_file"
        else
            echo -e "${RED}❌ Upload thất bại: $file${NC}" | tee -a "$log_file"
        fi
    done

    echo -e "${GREEN}📤 Hoàn tất quá trình upload backup lên storage!${NC}" | tee -a "$log_file"
}

# Nếu script được gọi trực tiếp, thực hiện upload
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    upload_backup "$@"
fi
