core_display_version_logic() {
    local channel="${1:-official}"

    local current_version_file="$CORE_CURRENT_VERSION"
    local latest_version=""

    if [[ ! -f "$current_version_file" ]]; then
        print_msg "error" "$ERROR_VERSION_CHANNEL_FILE_NOT_FOUND"
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
            print_msg "error" "$ERROR_VERSION_CHANNEL_INVALID_CHANNEL : $channel"
            return 1
            ;;
    esac

    CURRENT_VERSION=$(cat "$current_version_file")

    if [[ -z "$latest_version" ]]; then
        print_msg "error" "$ERROR_VERSION_CHANNEL_FAILED_FETCH_LATEST"
        return 1
    fi

    core_compare_versions "$CURRENT_VERSION" "$latest_version"
    result=$?

    if [[ "$result" -eq 2 ]]; then
        print_msg "info" "$INFO_LABEL_CORE_VERSION : $CURRENT_VERSION → ${RED}$latest_version${NC}"
    else
        print_msg "info" "$INFO_LABEL_CORE_VERSION : $CURRENT_VERSION ${GREEN}($MSG_LATEST)${NC}"
    fi
}