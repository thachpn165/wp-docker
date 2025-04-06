core_display_version_logic() {
    local channel="${1:-official}"

    local current_version_file="$BASE_DIR/version.txt"
    local latest_version=""

    if [[ ! -f "$current_version_file" ]]; then
        echo -e "${RED}${CROSSMARK} version.txt not found.${NC}"
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
            echo -e "${RED}${CROSSMARK} Invalid version channel: $channel${NC}"
            return 1
            ;;
    esac

    CURRENT_VERSION=$(cat "$current_version_file")

    if [[ -z "$latest_version" ]]; then
        echo -e "${RED}${CROSSMARK} Failed to fetch latest version for channel '$channel'${NC}"
        return 1
    fi

    core_compare_versions "$CURRENT_VERSION" "$latest_version"
    result=$?

    if [[ "$result" -eq 2 ]]; then
        echo -e "📦 WP Docker Version: ${CURRENT_VERSION} ${RED}(new version available: $latest_version)${NC}"
    else
        echo -e "${BLUE}📦 WP Docker Version:${NC} ${CURRENT_VERSION} ${GREEN}(latest)${NC}"
    fi
}