php_get_version() {
    local output_file="$BASE_DIR/php_versions.txt"
    local max_age_hours=6

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

    echo -e "${YELLOW}🔁 Đang tải danh sách từ Docker Hub...${NC}"
    all_tags=$(curl -s --max-time 15 "https://hub.docker.com/v2/repositories/bitnami/php-fpm/tags?page_size=100" \
        | grep -oE '"name":"[0-9]+\.[0-9]+\.[0-9]+"' \
        | cut -d':' -f2 | tr -d '"' \
        | sort -Vr)

    if [[ -z "$all_tags" ]]; then
        echo -e "${RED}⚠️ Không thể lấy dữ liệu từ Docker Hub. Sử dụng mặc định.${NC}"
        all_tags="8.4.5 8.4.4 8.3.14 8.3.13 8.2.12 8.2.11 8.1.19 8.1.18 7.4.33 7.4.32"
    fi

    : > "$output_file"
    used_prefixes=""
    for tag in $all_tags; do
        prefix=$(echo "$tag" | cut -d. -f1,2)
        count=$(grep -c "^$prefix\." "$output_file" || true)
        if [[ "$count" -lt 2 ]]; then
            echo "$tag" >> "$output_file"
        fi
        # Sau khi đã có 2 tag cho 5 nhóm => đủ 10 tag
        total=$(wc -l < "$output_file")
        if [[ "$total" -ge 10 ]]; then
            break
        fi
    done

    echo -e "${GREEN}✅ Đã lưu danh sách PHP vào: $output_file${NC}"
}
