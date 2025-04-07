# This script defines a function `php_get_version` that retrieves a list of PHP versions
# from the Docker Hub API and caches the results in a file. The function ensures that
# the cached data is not older than a specified maximum age (in hours). If the cache is
# outdated or does not exist, it fetches the latest PHP version tags from Docker Hub.

# Function: php_get_version
# Description:
#   Fetches and caches a list of PHP version tags from the Docker Hub API.
#   Ensures that the cached data is not older than the specified maximum age.
#   Limits the output to a maximum of 10 unique version tags, with at most 2 tags
#   per major.minor version prefix.
#
# Globals:
#   BASE_DIR - Base directory for the project (used to determine the output file path).
#   INFO_PHP_GETTING_LIST - Message to display when fetching the PHP version list.
#   SUCCESS_PHP_LIST_CACHED - Message to display when using cached PHP version list.
#   STEP_PHP_FETCHING_FROM_DOCKER - Message to display when fetching data from Docker Hub.
#   SUCCESS_PHP_LIST_SAVED - Message to display when the PHP version list is saved.
#
# Arguments:
#   None
#
# Outputs:
#   Writes the fetched PHP version tags to a file named `php_versions.txt` in the
#   `$BASE_DIR` directory.
#
# Behavior:
#   1. Checks if the cached file exists and is not older than the specified maximum age
#      (168 hours by default, equivalent to 7 days).
#   2. If the cache is valid, the function exits early and uses the cached data.
#   3. If the cache is outdated or does not exist, the function fetches PHP version tags
#      from the Docker Hub API.
#   4. Limits the fetched tags to a maximum of 10, ensuring no more than 2 tags per
#      major.minor version prefix.
#   5. Saves the filtered tags to the output file and removes temporary files.
#
# Notes:
#   - The function uses `curl` to fetch data from the Docker Hub API.
#   - The temporary file `/tmp/php_tags_all.tmp` is used to store intermediate results.
#   - The function handles both macOS (`darwin`) and Linux systems for file age calculation.
#   - The function ensures that API requests are limited to avoid excessive data fetching.
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