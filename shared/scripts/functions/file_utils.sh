#!/bin/bash

# Kiểm tra xem một tệp tin có tồn tại không
is_file_exist() {
    local file_path="$1"
    [[ -f "$file_path" ]]
}

# Kiểm tra xem một thư mục có tồn tại không
is_dir_exist() {
    local dir_path="$1"
    [[ -d "$dir_path" ]]
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
    if is_dir_exist "$dir_path"; then
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

# Hàm kiểm tra thư mục có tồn tại không
is_directory_exist() {
    local directory="$1"
    if [ -d "$directory" ]; then
        return 0  # Thư mục tồn tại
    else
        return 1  # Thư mục không tồn tại
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
