#!/bin/bash

show_docker_menu() {
    while true; do
        clear
        echo -e "${BLUE}========= ⚙️ DOCKER MANAGEMENT =========${NC}"
        echo -e "${GREEN}1.${NC} Rebuild NGINX Proxy"
        echo -e "${GREEN}2.${NC} Rebuild specific website"
        echo -e "${GREEN}3.${NC} Restart website container"
        echo -e "${GREEN}4.${NC} Set WordPress directory permissions"
        echo -e "${GREEN}5.${NC} Access PHP container shell"
        echo -e "${GREEN}0.${NC} Return to main menu"
        echo "--------------------------------------"
        read -p "Select function: " choice

        case "$choice" in
            1) docker_rebuild_nginx ;;
            2) docker_rebuild_site ;;
            3) docker_restart_site ;;
            4) docker_fix_permissions ;;
            5) docker_shell_php ;;
            0) break ;;
            *) echo "❌ Invalid selection!" && sleep 1 ;;
        esac
    done
}
