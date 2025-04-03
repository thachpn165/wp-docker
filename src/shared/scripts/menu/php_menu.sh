#!/bin/bash

# =====================================
# 💡 php_menu.sh – PHP Management Menu for WordPress Websites
# =====================================

CONFIG_FILE="shared/config/config.sh"

# Determine absolute path of `config.sh`
while [ ! -f "$CONFIG_FILE" ]; do
    CONFIG_FILE="../$CONFIG_FILE"
    if [ "$(pwd)" = "/" ]; then
        echo "${CROSSMARK} Error: config.sh not found!" >&2
        exit 1
    fi
done

source "$CONFIG_FILE"
export BASE_DIR
source "$FUNCTIONS_DIR/php/php_edit_conf.sh"
source "$FUNCTIONS_DIR/php/php_edit_phpini.sh"


# 📋 Main PHP Management Menu
php_menu() {
  while true; do
    clear
    echo -e "${CYAN}===== PHP VERSION MANAGEMENT =====${NC}"
    echo -e "${GREEN}[1]${NC} 🔀 Change PHP Version"
    echo -e "${GREEN}[2]${NC} 🔁 Rebuild PHP Container"
    echo -e "${GREEN}[3]${NC} ⚙️  Edit php-fpm.conf"
    echo -e "${GREEN}[4]${NC} 🛠️  Edit php.ini"
    echo -e "${GREEN}[5]${NC} ⬅️ Back"
    echo ""

    [[ "$TEST_MODE" != true ]] && read -p "Select a function (1-5): " choice
    case $choice in
      1) bash "$MENU_DIR/php_change_version_menu.sh"; read -p "Press Enter to continue..." ;;
      2) bash "$MENU_DIR/php_rebuild_container_menu.sh"; read -p "Press Enter to continue..." ;;
      3) edit_php_fpm_conf; read -p "Press Enter to continue..." ;;
      4) edit_php_ini; read -p "Press Enter to continue..." ;;
      5) break ;;
      *) echo -e "${RED}${WARNING} Invalid option!${NC}"; sleep 2 ;;
    esac
  done
}
