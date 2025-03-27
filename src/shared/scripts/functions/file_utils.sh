#!/bin/bash

# Kiểm tra xem một tệp tin có tồn tại không
is_file_exist() {
    local file_path="$1"
    [[ -f "$file_path" ]]
}


# Xóa tệp tin nếu nó tồn tại
remove_file() {
    local file_path="$1"
    if is_file_exist "$file_path"; then
        echo "🗑️ Đang xóa tệp tin: $file_path"
        rm -f "$file_path"
    fi
}

# Xóa thư mục nếu nó tồn tại
remove_directory() {
    local dir_path="$1"
    if is_directory_exist "$dir_path"; then
        echo "🗑️ Đang xóa thư mục: $dir_path"
        rm -rf "$dir_path"
    fi
}

# Sao chép tệp tin với kiểm tra lỗi
copy_file() {
    local src="$1"
    local dest="$2"
    if is_file_exist "$src"; then
        echo "📂 Sao chép tệp tin từ $src -> $dest"
        cp "$src" "$dest"
    else
        echo "❌ Lỗi: Không tìm thấy tệp tin nguồn: $src"
        return 1
    fi
}

# Hàm kiểm tra thư mục có tồn tại không, nếu không thì tự tạo thư mục
is_directory_exist() {
    local dir="$1"
    local create_if_missing="$2" # Nếu là "false" thì không tạo

    if [ ! -d "$dir" ]; then
        if [ "$create_if_missing" != "false" ]; then
            echo "📁 [DEBUG] Tạo thư mục: $dir"
            mkdir -p "$dir"
        else
            return 1
        fi
    fi
}



# Hỏi người dùng xác nhận hành động
confirm_action() {
    local message="$1"
    
    while true; do
        read -rp "$message (y/n): " response
        case "$response" in
            [Yy]*) return 0 ;;  # Xác nhận hành động
            [Nn]*) return 1 ;;  # Hủy hành động
            *) echo -e "${RED}⚠️ Vui lòng nhập 'y' hoặc 'n'.${NC}" ;;
        esac
    done
}

# Hàm hỗ trợ ghi log với timestamp, tránh trùng lặp log
log_with_time() {
    local message="$1"
    local formatted_time
    formatted_time="$(date '+%Y-%m-%d %H:%M:%S') - $message"

    # In ra terminal và ghi log, nhưng chỉ ghi log một lần
    echo -e "$formatted_time" | tee -a "$log_file" > /dev/null
}

# Hàm chạy lệnh trong thư mục sử dụng pushd/popd để đảm bảo lệnh chạy chính xác và trở về thư mục gốc
run_in_dir() {
  local target_dir="$1"
  shift

  if [[ ! -d "$target_dir" ]]; then
    echo -e "${RED}❌ Thư mục '$target_dir' không tồn tại!${NC}"
    return 1
  fi

  pushd "$target_dir" > /dev/null
  "$@"
  local status=$?
  popd > /dev/null
  return $status
}
