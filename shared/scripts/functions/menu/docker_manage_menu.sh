#!/bin/bash

show_docker_menu() {
    while true; do
        clear
        echo -e "${BLUE}========= ⚙️ QUẢN LÝ DOCKER =========${NC}"
        echo -e "${GREEN}1.${NC} Build lại NGINX Proxy"
        echo -e "${GREEN}2.${NC} Build lại website cụ thể"
        echo -e "${GREEN}3.${NC} Restart container website"
        echo -e "${GREEN}4.${NC} Thiết lập quyền thư mục WordPress"
        echo -e "${GREEN}5.${NC} Truy cập shell vào container PHP"
        echo -e "${GREEN}0.${NC} Quay lại menu chính"
        echo "--------------------------------------"
        read -p "Chọn chức năng: " choice

        case "$choice" in
            1) docker_rebuild_nginx ;;
            2) docker_rebuild_site ;;
            3) docker_restart_site ;;
            4) docker_fix_permissions ;;
            5) docker_shell_php ;;
            0) break ;;
            *) echo "❌ Lựa chọn không hợp lệ!" && sleep 1 ;;
        esac
    done
}
