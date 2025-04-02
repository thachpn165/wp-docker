reset_user_role_logic() {


    # Lấy tên website từ tham số site_name
    site_name="$1"  # site_name sẽ được truyền từ file menu hoặc CLI

    SITE_DIR="$SITES_DIR/$site_name"
    PHP_CONTAINER="$site_name-php"

    # **Chạy lệnh WP CLI để reset lại quyền**
    echo -e "${YELLOW}🔄 Đang thiết lập lại quyền Administrator về mặc định...${NC}"
    docker exec -u root "$PHP_CONTAINER" wp role reset --all --allow-root --path=/var/www/html

    echo -e "${GREEN}${CHECKMARK} Quyền Administrator trên website '$site_name' đã được thiết lập lại thành công.${NC}"
}
