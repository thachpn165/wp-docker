#!/bin/bash
#shellcheck disable=SC1091
safe_source "$FUNCTIONS_DIR/php_loader.sh"
safe_source "$CLI_DIR/php_version.sh"

# 📋 Main PHP Management Menu
php_menu() {
  while true; do
    print_msg title "$TITLE_MENU_PHP"
    print_msg label "${GREEN}1)${NC} $LABEL_MENU_PHP_CHANGE"
    print_msg label "${GREEN}2)${NC} $LABEL_MENU_PHP_REBUILD"
    print_msg label "${GREEN}3)${NC} $LABEL_MENU_PHP_EDIT_CONF"
    print_msg label "${GREEN}4)${NC} $LABEL_MENU_PHP_EDIT_INI"
    print_msg label "${GREEN}5)${NC} $LABEL_MENU_PHP_INSTALL_EXTENSION"
    print_msg label "${GREEN}6)${NC} $MSG_BACK"
    echo ""

    read -p "$MSG_SELECT_OPTION " choice
    
      case $choice in
        1) php_prompt_change_version; read -p "$MSG_PRESS_ENTER_CONTINUE" ;;
        2) php_prompt_rebuild_container; read -p "$MSG_PRESS_ENTER_CONTINUE" ;;
        3) edit_php_fpm_conf; read -p "$MSG_PRESS_ENTER_CONTINUE" ;;
        4) edit_php_ini; read -p "$MSG_PRESS_ENTER_CONTINUE" ;;
        5) php_prompt_install_extension; read -p "$MSG_PRESS_ENTER_CONTINUE" ;;
        6) break ;;
        *) print_msg error "$ERROR_SELECT_OPTION_INVALID" ;;
    esac
  done
}
