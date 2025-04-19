# =====================================
# php_get_version: Fetch and cache latest PHP-FPM versions from Docker Hub
# Save to $BASE_DIR/php_versions.txt
# Requires:
#   - curl for API requests
#   - Sorts and filters versions into a cached file for reuse
#   - Uses caching mechanism to reduce external API calls (7 days default)
# =====================================
php_get_version() {
    local output_file="$BASE_DIR/php_versions.txt"
    local max_age_hours=168 # 7 days
    local base_url="https://hub.docker.com/v2/repositories/bitnami/php-fpm/tags?page_size=1000"
    local temp_file="/tmp/php_tags_all.tmp"

    print_msg info "$INFO_PHP_GETTING_LIST"

    # Check if cached file is still valid
    if [[ -f "$output_file" ]]; then
        local file_age
        if [[ "$OSTYPE" == "darwin"* ]]; then
            file_age=$((($(date +%s) - $(stat -f %m "$output_file")) / 3600))
        else
            file_age=$((($(date +%s) - $(stat -c %Y "$output_file")) / 3600))
        fi

        if ((file_age < max_age_hours)); then
            print_msg success "$SUCCESS_PHP_LIST_CACHED"
            debug_log "[PHP VERSION] Cache valid ($file_age h old): $output_file"
            return 0
        fi
    fi

    # Fetch from Docker Hub (no pagination)
    print_msg step "$STEP_PHP_FETCHING_FROM_DOCKER"
    debug_log "[PHP VERSION] Fetching Docker Hub API: $base_url"

    : >"$temp_file"

    local page_data tags
    page_data=$(curl -s --max-time 15 "$base_url")
    tags=$(echo "$page_data" | grep -oE '"name":"[0-9]+\.[0-9]+\.[0-9]+"' | cut -d':' -f2 | tr -d '"')
    echo "$tags" >>"$temp_file"

    local total_tags
    total_tags=$(wc -l < "$temp_file")
    debug_log "[PHP VERSION] Fetched $total_tags tags from Docker Hub"
    debug_log "[PHP VERSION] Raw tag list (top 10):"
    head -n 10 "$temp_file" | while read -r t; do debug_log "  → $t"; done

    # Filter and save output: max 2 per minor version
    : >"$output_file"
    while read -r tag; do
        prefix=$(echo "$tag" | cut -d. -f1,2)
        count=$(grep -c "^$prefix\." "$output_file" || true)
        if [[ "$count" -lt 2 ]]; then
            echo "$tag" >>"$output_file"
            debug_log "[PHP VERSION] Added $tag (prefix=$prefix, current=$count)"
        fi
    done < <(sort -Vr "$temp_file")

    local final_count
    final_count=$(wc -l < "$output_file")
    print_msg success "$(printf "$SUCCESS_PHP_LIST_SAVED" "$output_file")"
    debug_log "[PHP VERSION] Final saved versions ($final_count):"
    cat "$output_file" | while read -r v; do debug_log "  • $v"; done
}