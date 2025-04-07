core_display_version_logic() {
    local channel="${1:-official}"
    local current_version_file="$BASE_DIR/version.txt"
    local latest_version=""

    debug_log "[core_display_version_logic] Channel: $channel"
    debug_log "[core_display_version_logic] Current version file: $current_version_file"

    if [[ ! -f "$current_version_file" ]]; then
        print_msg error "$ERROR_VERSION_CHANNEL_FILE_NOT_FOUND"
        return 1
    fi

    case "$channel" in
        official)
            latest_version=$(core_version_main_cache)
            ;;
        nightly)
            latest_version=$(core_version_dev_cache)
            ;;
        *)
            print_msg error "$ERROR_VERSION_CHANNEL_INVALID_CHANNEL - $channel"
            return 1
            ;;
    esac

    CURRENT_VERSION=$(cat "$current_version_file")
    debug_log "[core_display_version_logic] Current version: $CURRENT_VERSION"
    debug_log "[core_display_version_logic] Latest version: $latest_version"

    if [[ -z "$latest_version" ]]; then
        print_msg error "$(printf "$ERROR_VERSION_CHANNEL_FAILED_FETCH_LATEST" "$channel")"
        return 1
    fi

    core_compare_versions "$CURRENT_VERSION" "$latest_version"
    result=$?

    if [[ "$result" -eq 2 ]]; then
        print_msg warning "$(printf "$WARNING_CORE_VERSION_NEW_AVAILABLE" "$CURRENT_VERSION" "$latest_version")"
    else
        print_msg info "$(printf "$INFO_CORE_VERSION_LATEST" "$CURRENT_VERSION")"
    fi
}