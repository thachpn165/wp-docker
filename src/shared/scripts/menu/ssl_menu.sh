#!/bin/bash
source "$FUNCTIONS_DIR/ssl_loader.sh"
# Header menu
print_ssl_menu_header() {
    echo -e "\n${MAGENTA}===========================================${NC}"
    echo -e "         🔐 SSL CERTIFICATE MANAGEMENT"
    echo -e "${MAGENTA}===========================================${NC}"
}

# Display menu
ssl_menu() {
    while true; do
        print_ssl_menu_header
        echo -e "${GREEN}1)${NC} Generate self-signed SSL"
        echo -e "${GREEN}2)${NC} Install manual SSL (Paid SSL)"
        echo -e "${GREEN}3)${NC} Edit SSL"
        echo -e "${GREEN}4)${NC} Install Let's Encrypt SSL (free)"
        echo -e "${GREEN}5)${NC} Check SSL certificate status"
        echo -e "${GREEN}6)${NC} Back to main menu"
        echo ""

        [[ "$TEST_MODE" != true ]] && read -p "🔹 Select an option (1-7): " choice
        case "$choice" in
            1)
                bash "$MENU_DIR/ssl/ssl_generate_self_signed_menu.sh"
                [[ "$TEST_MODE" != true ]] && read -p "Press Enter to continue..."
                ;;
            2)
                bash "$MENU_DIR/ssl/ssl_manual_install_menu.sh"
                [[ "$TEST_MODE" != true ]] && read -p "Press Enter to continue..."
                ;;
            3)
                bash "$MENU_DIR/ssl/ssl_edit_cert_menu.sh"
                [[ "$TEST_MODE" != true ]] && read -p "Press Enter to continue..."
                ;;
            4)
                bash "$MENU_DIR/ssl/ssl_install_letsencrypt_menu.sh"
                [[ "$TEST_MODE" != true ]] && read -p "Press Enter to continue..."
                ;;
            5)
                ssl_check_certificate_status
                [[ "$TEST_MODE" != true ]] && read -p "Press Enter to continue..."
                ;;
            6)
                break
                ;;
            *)
                echo -e "${RED}⚠️ Invalid option. Please try again.${NC}"
                sleep 1
                ;;
        esac
    done
}
