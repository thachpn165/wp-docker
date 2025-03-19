# Hiển thị danh sách website để chọn
select_website() {
    local sites=($(ls -d $SITES_DIR/*/ | xargs -n 1 basename))
    if [[ ${#sites[@]} -eq 0 ]]; then
        echo -e "${RED}❌ Không tìm thấy website nào trong $SITES_DIR${NC}"
        return 1
    fi

    echo -e "${BLUE}🔹 Chọn một website:${NC}"
    echo ""
    select SITE_NAME in "${sites[@]}"; do
        if [[ -n "$SITE_NAME" ]]; then
            echo -e "${GREEN}✅ Đã chọn: $SITE_NAME${NC}"
            break
        else
            echo -e "${RED}❌ Lựa chọn không hợp lệ!${NC}"
        fi
    done
}
