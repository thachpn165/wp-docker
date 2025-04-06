#!/bin/bash
source "$FUNCTIONS_DIR/php/php_edit_conf.sh"
source "$FUNCTIONS_DIR/php/php_edit_phpini.sh"


# 📋 Main PHP Management Menu
php_menu() {
    print_msg title "$TITLE_MENU_PHP"
    print_msg label "${GREEN}1)${NC} $LABEL_MENU_PHP_CHANGE"
    print_msg label "${GREEN}2)${NC} $LABEL_MENU_PHP_REBUILD"
    print_msg label "${GREEN}3)${NC} $LABEL_MENU_PHP_EDIT_CONF"
    print_msg label "${GREEN}4)${NC} $LABEL_MENU_PHP_EDIT_INI"
    print_msg label "${GREEN}5)${NC} $MSG_BACK"
    echo ""

    read -p "$MSG_SELECT_OPTION " choice
    while true; do
      case $choice in
        1) bash "$MENU_DIR/php/php_change_version_menu.sh"; read -p "$MSG_PRESS_ENTER_CONTINUE" ;;
        2) bash "$MENU_DIR/php/php_rebuild_container_menu.sh"; read -p "$MSG_PRESS_ENTER_CONTINUE" ;;
        3) edit_php_fpm_conf; read -p "$MSG_PRESS_ENTER_CONTINUE" ;;
        4) edit_php_ini; read -p "$MSG_PRESS_ENTER_CONTINUE" ;;
        5) break ;;
        *) print_msg error "$ERROR_SELECT_OPTION_INVALID" ;;
      esac
  done
}
