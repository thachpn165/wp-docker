#!/bin/bash

core_display_version_logic() {
    local channel="${1:-official}"

    local current_version_file="$BASE_DIR/version.txt"
    local latest_version_url=""

    case "$channel" in
        official)
            latest_version_url="$CORE_LATEST_VERSION"
            ;;
        nightly)
            latest_version_url="$CORE_NIGHTLY_VERSION"
            ;;
        *)
            echo -e "${RED}${CROSSMARK} Invalid version channel: $channel${NC}"
            return 1
            ;;
    esac

    if [[ ! -f "$current_version_file" ]]; then
        echo -e "${RED}${CROSSMARK} version.txt not found.${NC}"
        return 1
    fi

    CURRENT_VERSION=$(cat "$current_version_file")
    LATEST_VERSION=$(curl -s "$latest_version_url")

    if [[ -z "$LATEST_VERSION" ]]; then
        echo -e "${RED}${CROSSMARK} Failed to fetch latest version from $latest_version_url${NC}"
        return 1
    fi

    # So sánh phiên bản
    core_compare_versions "$CURRENT_VERSION" "$LATEST_VERSION"
    result=$?

    if [[ "$result" -eq 2 ]]; then
        echo -e "📦 WP Docker Version: ${CURRENT_VERSION} ${RED}(new version available: $LATEST_VERSION)${NC}"
    else
        echo -e "${BLUE}📦 WP Docker Version:${NC} ${CURRENT_VERSION} ${GREEN}(latest)${NC}"
    fi
}