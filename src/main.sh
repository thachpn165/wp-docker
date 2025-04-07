# =============================================
# 🚀 WP Docker Main Entry Script
# ---------------------------------------------
# This script is the main entry point of the WP Docker system.
# It loads global configurations, imports all menu modules,
# and displays the interactive CLI menu for managing WordPress projects.
#
# Features:
# - System setup initialization
# - System information and Docker status overview
# - Access to all feature menus (Website, SSL, Backup, PHP, Rclone, etc.)
# - Supports i18n, DEBUG_MODE, and DEV_MODE
# =============================================

# 🔧 Auto-detect BASE_DIR and load global configuration
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
  if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
    source "$SCRIPT_PATH/shared/config/load_config.sh"
    break
  fi
  SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done

# 📦 Import all menu modules
source "$MENU_DIR/menu_utils.sh"
source "$MENU_DIR/website_management_menu.sh"
source "$MENU_DIR/wordpress_tools_menu.sh"
source "$MENU_DIR/system_tools_menu.sh"
source "$MENU_DIR/backup_menu.sh"
source "$MENU_DIR/rclone_menu.sh"
source "$MENU_DIR/ssl_menu.sh"
source "$MENU_DIR/php_menu.sh"
source "$MENU_DIR/database_menu.sh"
source "$FUNCTIONS_DIR/core_loader.sh"
# ⚙️ Run initial system setup (timezone, permissions, etc.)
source "$SCRIPTS_DIR/setup-system.sh"

# 🏆 Display system information and version header
print_header() {
    clear
    #echo -e "\n\n\n"
    get_system_info
    echo -e "${MAGENTA}==============================================${NC}"
    print_msg title "$TITLE_MENU_WELCOME"
    echo -e "${MAGENTA}==============================================${NC}"
    echo ""
    
    print_msg label "$LABEL_DOCKER_STATUS"
    print_msg sub-label "- $LABEL_DOCKER_NETWORK_STATUS: $(check_docker_network)"
    print_msg sub-label "- $LABEL_DOCKER_NGINX_STATUS: $(check_nginx_status)"

    echo ""
    print_msg label "$LABEL_SYSTEM_INFO"
    print_msg sub-label "- ${STRONG}$LABEL_CPU${NC}: ${CPU_MODEL} (${TOTAL_CPU} cores)"
    print_msg sub-label "- ${STRONG}$LABEL_RAM${NC}: ${USED_RAM}MB / ${TOTAL_RAM}MB"
    print_msg sub-label "- ${STRONG}$LABEL_DISK${NC}: ${DISK_USAGE}"
    print_msg sub-label "- ${STRONG}$LABEL_IPADDR${NC}: ${IP_ADDRESS}"
    echo ""
    print_msg label "${STRONG}$LABEL_VERSION_CHANNEL${NC}: ${YELLOW}${CORE_CHANNEL}${NC}"
    core_display_version
    echo -e "${MAGENTA}==============================================${NC}"
}

# 🎯 Main interactive menu loop
while true; do
    print_header
    print_msg title "$TITLE_MENU_MAIN"
    print_msg label "${GREEN}[1]${NC} ${STRONG}$LABEL_MENU_MAIN_WEBSITE${NC}"
    print_msg label "${GREEN}[2]${NC} ${STRONG}$LABEL_MENU_MAIN_SSL${NC}"
    print_msg label "${GREEN}[3]${NC} ${STRONG}$LABEL_MENU_MAIN_SYSTEM${NC}"
    print_msg label "${GREEN}[4]${NC} ${STRONG}$LABEL_MENU_MAIN_RCLONE${NC}"
    print_msg label "${GREEN}[5]${NC} ${STRONG}$LABEL_MENU_MAIN_WORDPRESS${NC}"
    print_msg label "${GREEN}[6]${NC} ${STRONG}$LABEL_MENU_MAIN_BACKUP${NC}"
    print_msg label "${GREEN}[7]${NC} ${STRONG}$LABEL_MENU_MAIN_WORDPRESS_CACHE${NC}"
    print_msg label "${GREEN}[8]${NC} ${STRONG}$LABEL_MENU_MAIN_PHP${NC}"
    print_msg label "${GREEN}[9]${NC} ${STRONG}$LABEL_MENU_MAIN_DATABASE${NC}"
    print_msg label "${GREEN}[10]${NC} ${STRONG}$LABEL_MENU_MAIN_UPDATE${NC}"
    print_msg label "${GREEN}[11]${NC} ${RED}$MSG_EXIT${NC}"

    [[ "$TEST_MODE" != true ]] && read -p "${MSG_SELECT_OPTION}: " choice
    # 🧭 Handle user menu selection
    case "$choice" in
        1) website_management_menu ;;
        2) ssl_menu ;;
        3) system_tools_menu ;;
        4) rclone_menu ;;
        5) wordpress_tools_menu ;;
        6) backup_menu ;;
        7) bash "$MENU_DIR/wordpress/wordpress_setup_cache_menu.sh"; read -p "$MSG_PRESS_ENTER_CONTINUE" ;;
        8) php_menu ;;
        9) database_menu ;;
        10) echo "coming soon" ;;  # Call function to display version and update
        11) print_msg progress "$MSG_EXITING" && exit 0 ;;
        *) 
            print_msg error "$ERROR_SELECT_OPTION_INVALID"
            sleep 2 
            ;;
    esac
done
