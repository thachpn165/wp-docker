#!/bin/bash

# Load configuration
CONFIG_FILE="shared/config/config.sh"
while [ ! -f "$CONFIG_FILE" ]; do
    CONFIG_FILE="../$CONFIG_FILE"
    if [ "$(pwd)" = "/" ]; then
        echo "❌ Error: config.sh not found!" >&2
        exit 1
    fi
done
source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/ssl/ssl_generate_self_signed.sh"
source "$FUNCTIONS_DIR/ssl/ssl_install_manual.sh"
source "$FUNCTIONS_DIR/ssl/ssl_edit_cert.sh"
source "$FUNCTIONS_DIR/ssl/ssl_install_letsencrypt.sh"
source "$FUNCTIONS_DIR/ssl/ssl_check_cert_status.sh"

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
        echo -e "${GREEN}1)${NC} Generate self-signed certificate"
        echo -e "${GREEN}2)${NC} Install manual certificate (.crt/.key)"
        echo -e "${GREEN}3)${NC} Edit current SSL certificate"
        echo -e "${GREEN}4)${NC} Install Let's Encrypt certificate (free)"
        echo -e "${GREEN}5)${NC} Check SSL certificate status"
        echo -e "${GREEN}6)${NC} List domains with SSL"
        echo -e "${GREEN}7)${NC} Back to main menu"
        echo ""

        read -p "🔹 Select an option (1-7): " choice
        case "$choice" in
            1)
                ssl_generate_self_signed
                read -p "Press Enter to continue..."
                ;;
            2)
                ssl_install_manual_cert
                read -p "Press Enter to continue..."
                ;;
            3)
                ssl_edit_certificate
                read -p "Press Enter to continue..."
                ;;
            4)
                ssl_install_lets_encrypt
                read -p "Press Enter to continue..."
                ;;
            5)
                ssl_check_certificate_status
                read -p "Press Enter to continue..."
                ;;
            6)
                echo -e "\n🛠️ [IN DEVELOPMENT] List of domains with SSL"
                read -p "Press Enter to continue..."
                ;;
            7)
                break
                ;;
            *)
                echo -e "${RED}⚠️ Invalid option. Please try again.${NC}"
                sleep 1
                ;;
        esac
    done
}
