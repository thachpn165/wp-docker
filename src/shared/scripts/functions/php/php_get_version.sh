
php_get_version() {
    local output_file="$BASE_DIR/php_versions.txt"
    local max_age_hours=168 # 7 ngày
    local base_url="https://hub.docker.com/v2/repositories/bitnami/php-fpm/tags?page_size=100"
    local temp_file="/tmp/php_tags_all.tmp"
    local next_url="$base_url"

    print_msg info "$INFO_PHP_GETTING_LIST"

    # Kiểm tra cache đã cũ chưa
    if [[ -f "$output_file" ]]; then
        local file_age
        if [[ "$OSTYPE" == "darwin"* ]]; then
            file_age=$(( ( $(date +%s) - $(stat -f %m "$output_file") ) / 3600 ))
        else
            file_age=$(( ( $(date +%s) - $(stat -c %Y "$output_file") ) / 3600 ))
        fi

        if (( file_age < max_age_hours )); then
            print_msg success "$SUCCESS_PHP_LIST_CACHED"
            return 0
        fi
    fi

    print_msg step "$STEP_PHP_FETCHING_FROM_DOCKER"
    debug_log "[PHP VERSION] Start fetching from Docker Hub API..."
    : > "$temp_file"

    while [[ -n "$next_url" ]]; do
        page_data=$(curl -s --max-time 15 "$next_url")
        tags=$(echo "$page_data" | grep -oE '"name":"[0-9]+\.[0-9]+\.[0-9]+"' | cut -d':' -f2 | tr -d '"')
        echo "$tags" >> "$temp_file"

        if [[ $(wc -l < "$temp_file") -gt 50 ]]; then
            break
        fi

        next_url=$(echo "$page_data" | grep -oE '"next":"[^"]+"' | cut -d':' -f2- | tr -d '"')
        next_url=${next_url//\\u0026/&}
    done

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
    print_msg success "$(printf "$SUCCESS_PHP_LIST_SAVED" "$output_file")"
}