#!/bin/bash
wordpress_reset_wp_database_logic() {
    domain="$1"  # site_name sẽ được truyền từ file menu hoặc CLI
    SITE_DIR="$SITES_DIR/$domain"
    ENV_FILE="$SITE_DIR/.env"

    # **Lấy thông tin database từ .env**
    if [ -f "$ENV_FILE" ]; then
        source "$ENV_FILE"
    else
        #echo -e "${RED}${CROSSMARK} Không tìm thấy file .env cho site '$domain'!${NC}"
        print_msg error "$ERROR_ENV_NOT_FOUND : $ENV_FILE ($domain)" 
        exit 1
    fi

    # **Thực hiện reset database bằng hàm utils**
    db_reset_database "$domain" "$MYSQL_USER" "$MYSQL_PASSWORD" "$MYSQL_DATABASE"
}
