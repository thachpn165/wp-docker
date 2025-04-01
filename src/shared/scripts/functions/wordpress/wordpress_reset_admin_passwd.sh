#!/bin/bash

reset_admin_password_logic() {
    # Kiểm tra xem có truyền vào tên website không
    
    # 📋 Hiển thị danh sách website để chọn
    site_list=($(ls -1 "$SITES_DIR"))

    if [ ${#site_list[@]} -eq 0 ]; then
        echo -e "${RED}❌ Không có website nào để reset mật khẩu.${NC}"
        exit 1
    fi

    # Logic để chọn website và tài khoản cần reset mật khẩu
    site_name="${site_list[$1]}"
    SITE_DIR="$SITES_DIR/$site_name"
    PHP_CONTAINER="$site_name-php"

    # Lấy danh sách người dùng
    user_id="$2"

    # Tạo mật khẩu ngẫu nhiên 18 ký tự không có ký tự đặc biệt
    new_password=$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 18)

    # Cập nhật mật khẩu
    docker exec -u root "$PHP_CONTAINER" wp user update "$user_id" --user_pass="$new_password" --allow-root --path=/var/www/html

    echo -e "${GREEN}✅ Mật khẩu mới của tài khoản ID $user_id: $new_password${NC}"
    echo -e "${YELLOW}⚠️ Hãy lưu mật khẩu này ở nơi an toàn!${NC}"
}
