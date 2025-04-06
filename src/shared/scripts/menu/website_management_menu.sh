# =====================================
# 🌍 website_management_menu.sh – WordPress Website Management Menu
# =====================================

# Load website management functions
source "$FUNCTIONS_DIR/website_loader.sh"

# Display website management menu
website_management_menu() {
  while true; do
    clear
    print_msg title "$TITLE_MENU_WEBSITE"
    print_msg label "${GREEN}[1]${NC} $LABEL_MENU_WEBISTE_CREATE"
    print_msg label "${GREEN}[2]${NC} $LABEL_MENU_WEBSITE_DELETE"
    print_msg label "${GREEN}[3]${NC} $LABEL_MENU_WEBSITE_LIST"
    print_msg label "${GREEN}[4]${NC} $LABEL_MENU_WEBSITE_RESTART"
    print_msg label "${GREEN}[5]${NC} $LABEL_MENU_WEBSITE_LOGS"
    print_msg label "${GREEN}[6]${NC} $LABEL_MENU_WEBSITE_INFO"
    print_msg label "${GREEN}[7]${NC} $LABEL_MENU_WEBSITE_UPDATE_TEMPLATE"
    print_msg label "${GREEN}[8]${NC} $MSG_BACK"
    echo ""

    read -p "$MSG_SELECT_OPTION " sub_choice
    case $sub_choice in
      1) bash "$MENU_DIR/website/website_create_menu.sh"; read -p "$MSG_PRESS_ENTER_CONTINUE" ;;
      2) bash "$MENU_DIR/website/website_delete_menu.sh"; read -p "$MSG_PRESS_ENTER_CONTINUE" ;;
      3) bash "$MENU_DIR/website/website_list_menu.sh"; read -p "$MSG_PRESS_ENTER_CONTINUE" ;;
      4) bash "$MENU_DIR/website/website_restart_menu.sh"; read -p "$MSG_PRESS_ENTER_CONTINUE" ;;
      5) bash "$MENU_DIR/website/website_logs_menu.sh"; read -p "$MSG_PRESS_ENTER_CONTINUE" ;;
      6) bash "$MENU_DIR/website/website_info_menu.sh"; read -p "$MSG_PRESS_ENTER_CONTINUE" ;;
      7) bash "$MENU_DIR/website/website_update_template_menu.sh"; read -p "$MSG_PRESS_ENTER_CONTINUE" ;;
      8) break ;;
      *)
        print_msg error "$ERROR_SELECT_OPTION_INVALID"
        sleep 1
        ;;
    esac
  done
}