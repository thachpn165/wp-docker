wordpress_auto_update_plugin_logic() {

    site_name="$1"  # site_name sẽ được truyền từ file menu hoặc CLI

    SITE_DIR="$SITES_DIR/$site_name"
    PHP_CONTAINER="$site_name-php"

    # **Lấy danh sách plugin hiện có**
    echo -e "${YELLOW}📋 Danh sách plugin trên website '$site_name':${NC}"
    docker exec -u root "$PHP_CONTAINER" wp plugin list --field=name --allow-root --path=/var/www/html

    # **Xử lý bật/tắt tự động cập nhật plugin**
    if [[ "$2" == "enable" ]]; then
        echo -e "${YELLOW}🔄 Đang bật tự động cập nhật cho toàn bộ plugin...${NC}"
        docker exec -u root "$PHP_CONTAINER" wp plugin auto-updates enable --all --allow-root --path=/var/www/html
        echo -e "${GREEN}${CHECKMARK} Tự động cập nhật đã được bật cho tất cả plugin trên '$site_name'.${NC}"
    elif [[ "$2" == "disable" ]]; then
        echo -e "${YELLOW}🔄 Đang tắt tự động cập nhật cho toàn bộ plugin...${NC}"
        docker exec -u root "$PHP_CONTAINER" wp plugin auto-updates disable --all --allow-root --path=/var/www/html
        echo -e "${GREEN}${CHECKMARK} Tự động cập nhật đã được tắt cho tất cả plugin trên '$site_name'.${NC}"
    else
        echo -e "${RED}${CROSSMARK} Lựa chọn không hợp lệ.${NC}"
        exit 1
    fi
}