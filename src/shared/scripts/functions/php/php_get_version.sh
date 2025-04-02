php_get_version() {
    local output_file="$BASE_DIR/php_versions.txt"
    local max_age_hours=168 # 7 days
    local base_url="https://hub.docker.com/v2/repositories/bitnami/php-fpm/tags?page_size=100"
    local temp_file="/tmp/php_tags_all.tmp"
    local next_url="$base_url"

    echo -e "${CYAN}🌐 Checking PHP version list...${NC}"

    # Check cache
    if [[ -f "$output_file" ]]; then
        local file_age
        if [[ "$OSTYPE" == "darwin"* ]]; then
            file_age=$(( ( $(date +%s) - $(stat -f %m "$output_file") ) / 3600 ))
        else
            file_age=$(( ( $(date +%s) - $(stat -c %Y "$output_file") ) / 3600 ))
        fi

        if (( file_age < max_age_hours )); then
            echo -e "${GREEN}${CHECKMARK} PHP list is available (cache < ${max_age_hours}h).${NC}"
            return 0
        fi
    fi

    echo -e "${YELLOW}🔁 Downloading multiple pages from Docker Hub...${NC}"
    : > "$temp_file"

    # Recursively download pages until enough data
    while [[ -n "$next_url" ]]; do
        page_data=$(curl -s --max-time 15 "$next_url")
        tags=$(echo "$page_data" | grep -oE '"name":"[0-9]+\.[0-9]+\.[0-9]+"' | cut -d':' -f2 | tr -d '"')
        echo "$tags" >> "$temp_file"

        # Early stop if >30 tags (reduce API calls)
        if [[ $(wc -l < "$temp_file") -gt 50 ]]; then
            break
        fi

        # Get next page
        next_url=$(echo "$page_data" | grep -oE '"next":"[^"]+"' | cut -d':' -f2- | tr -d '"')
        next_url=${next_url//\\u0026/&} # decode URL
    done

    # Group by major.minor prefix and select 2 latest tags for each group
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
    echo -e "${GREEN}${CHECKMARK} PHP list has been saved to: $output_file${NC}"
}
