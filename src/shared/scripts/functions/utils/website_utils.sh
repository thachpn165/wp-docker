# Display list of websites for selection
select_website() {
    if [[ -z "$SITES_DIR" ]]; then
        echo -e "${RED}${CROSSMARK} SITES_DIR is not defined.${NC}"
        return 1
    fi

    local sites=()
    while IFS= read -r -d '' dir; do
        sites+=("$(basename "$dir")")
    done < <(find "$SITES_DIR" -mindepth 1 -maxdepth 1 -type d -print0)

    if [[ ${#sites[@]} -eq 0 ]]; then
        echo -e "${RED}${CROSSMARK} No websites found in $SITES_DIR${NC}"
        return 1
    fi

    if [[ "$TEST_MODE" == true ]]; then
        SITE_DOMAIN="${TEST_SITE_DOMAIN:-${sites[0]}}"
        echo -e "${YELLOW}🧪 TEST_MODE: auto-selecting $SITE_DOMAIN${NC}"
    else
        echo -e "\n📄 Available websites:"
        for i in "${!sites[@]}"; do
            echo "  $((i+1)). ${sites[$i]}"
        done

        SELECTED_WEBSITE=$(select_from_list "🔹 Select a website:" "${sites[@]}")
        if [[ -z "$SELECTED_WEBSITE" ]]; then
            echo -e "${RED}${CROSSMARK} Invalid selection!${NC}"
            return 1
        fi

        SITE_DOMAIN="$SELECTED_WEBSITE"
    fi

    echo -e "${GREEN}${CHECKMARK} Selected: $SITE_DOMAIN${NC}"
}