reset_user_role_logic() {


    # Lấy tên website từ tham số site_name
    domain="$1"  # site_name sẽ được truyền từ file menu hoặc CLI

    SITE_DIR="$SITES_DIR/$domain"
    PHP_CONTAINER="$domain-php"

    # **Chạy lệnh WP CLI để reset lại quyền**
    echo -e "${YELLOW}🔄 Đang thiết lập lại quyền Administrator về mặc định...${NC}"
    docker exec -u root "$PHP_CONTAINER" wp role reset --all --allow-root --path=/var/www/html

    echo -e "${GREEN}${CHECKMARK} Quyền Administrator trên website '$domain' đã được thiết lập lại thành công.${NC}"
}
