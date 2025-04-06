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
        print_and_debug error "$ERROR_NO_WEBSITES_FOUND $SITES_DIR"
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

        SELECTED_WEBSITE=$(select_from_list "$PROMPT_WEBSITE_SELECT" "${sites[@]}")
        if [[ -z "$SELECTED_WEBSITE" ]]; then
            print_msg error "$ERROR_SELECT_OPTION_INVALID"
            return 1
        fi

        SITE_DOMAIN="$SELECTED_WEBSITE"
    fi
    
    # Corrected assignment: no spaces around "=" in bash
    domain="$SITE_DOMAIN"
    
    print_and_debug info "$MSG_WEBSITE_SELECTED: $domain"
}