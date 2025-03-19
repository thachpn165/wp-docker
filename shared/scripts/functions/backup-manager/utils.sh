#!/bin/bash

ensure_directory_exists() {
    local dir_path="$1"
    if [[ ! -d "$dir_path" ]]; then
        echo "📂 Tạo thư mục: $dir_path"
        mkdir -p "$dir_path"
    fi
}
