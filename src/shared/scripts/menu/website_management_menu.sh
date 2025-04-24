# =====================================
# 🌍 website_management_menu.sh – WordPress Website Management Menu
# =====================================
#shellcheck disable=SC1091

# Load website management functions
safe_source "$FUNCTIONS_DIR/website_loader.sh"
safe_source "$CLI_DIR/website_create.sh"
safe_source "$CLI_DIR/website_manage.sh"
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
    print_msg label "${GREEN}[7]${NC} ${STRONG}$LABEL_MENU_WORDPRESS_MIGRATION${NC}"
    print_msg label "${GREEN}[8]${NC} $MSG_BACK"
    echo ""

    read -p "$MSG_SELECT_OPTION " sub_choice
    case $sub_choice in
    1)
      website_prompt_create
      read -p "$MSG_PRESS_ENTER_CONTINUE"
      ;;
    2)
      website_prompt_delete
      read -p "$MSG_PRESS_ENTER_CONTINUE"
      ;;
    3)
      website_cli_list
      read -p "$MSG_PRESS_ENTER_CONTINUE"
      ;;
    4)
      website_logic_restart
      read -p "$MSG_PRESS_ENTER_CONTINUE"
      ;;
    5)
      website_logic_logs
      read -p "$MSG_PRESS_ENTER_CONTINUE"
      ;;
    6)
      website_logic_info
      read -p "$MSG_PRESS_ENTER_CONTINUE"
      ;;
    7) wordpress_prompt_migration; read -p "$MSG_PRESS_ENTER_CONTINUE" ;;
    8) break ;;
    *)
      print_msg error "$ERROR_SELECT_OPTION_INVALID"
      sleep 1
      ;;
    esac
  done
}
