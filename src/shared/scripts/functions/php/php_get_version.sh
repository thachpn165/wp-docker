php_get_version() {
    local output_file="$BASE_DIR/php_versions.txt"
    local max_age_hours=6
    local base_url="https://hub.docker.com/v2/repositories/bitnami/php-fpm/tags?page_size=100"
    local temp_file="/tmp/php_tags_all.tmp"
    local next_url="$base_url"

    echo -e "${CYAN}🌐 Đang kiểm tra danh sách phiên bản PHP...${NC}"

    # Kiểm tra cache
    if [[ -f "$output_file" ]]; then
        local file_age
        if [[ "$OSTYPE" == "darwin"* ]]; then
            file_age=$(( ( $(date +%s) - $(stat -f %m "$output_file") ) / 3600 ))
        else
            file_age=$(( ( $(date +%s) - $(stat -c %Y "$output_file") ) / 3600 ))
        fi

        if (( file_age < max_age_hours )); then
            echo -e "${GREEN}✅ Danh sách PHP đã có sẵn (cache < ${max_age_hours}h).${NC}"
            return 0
        fi
    fi

    echo -e "${YELLOW}🔁 Đang tải nhiều trang từ Docker Hub...${NC}"
    : > "$temp_file"

    # Đệ quy tải các trang đến khi đủ dữ liệu
    while [[ -n "$next_url" ]]; do
        page_data=$(curl -s --max-time 15 "$next_url")
        tags=$(echo "$page_data" | grep -oE '"name":"[0-9]+\.[0-9]+\.[0-9]+"' | cut -d':' -f2 | tr -d '"')
        echo "$tags" >> "$temp_file"

        # Dừng sớm nếu đủ >30 tag (giảm số lần gọi)
        if [[ $(wc -l < "$temp_file") -gt 50 ]]; then
            break
        fi

        # Lấy trang kế tiếp
        next_url=$(echo "$page_data" | grep -oE '"next":"[^"]+"' | cut -d':' -f2- | tr -d '"')
        next_url=${next_url//\\u0026/&} # decode URL
    done

    # Gom theo prefix major.minor và chọn 2 tag mới nhất cho mỗi nhóm
    : > "$output_file"
    used_prefixes=""
    while read -r tag; do
        prefix=$(echo "$tag" | cut -d. -f1,2)
        count=$(grep -c "^$prefix\." "$output_file" || true)
        if [[ "$count" -lt 2 ]]; then
            echo "$tag" >> "$output_file"
        fi
        total=$(wc -l < "$output_file")
        if [[ "$total" -ge 10 ]]; then
            break
        fi
    done < <(sort -Vr "$temp_file")

    rm -f "$temp_file"
    echo -e "${GREEN}✅ Đã lưu danh sách PHP vào: $output_file${NC}"
}
