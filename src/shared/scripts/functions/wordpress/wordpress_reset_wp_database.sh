#!/bin/bash
wordpress_reset_wp_database_logic() {
    site_name="$1"  # site_name sẽ được truyền từ file menu hoặc CLI
    SITE_DIR="$SITES_DIR/$site_name"
    ENV_FILE="$SITE_DIR/.env"

    # **Lấy thông tin database từ .env**
    if [ -f "$ENV_FILE" ]; then
        source "$ENV_FILE"
    else
        echo -e "${RED}❌ Không tìm thấy file .env cho site '$site_name'!${NC}"
        exit 1
    fi

    # **Thực hiện reset database bằng hàm utils**
    db_reset_database "$site_name" "$MYSQL_USER" "$MYSQL_PASSWORD" "$MYSQL_DATABASE"
}
