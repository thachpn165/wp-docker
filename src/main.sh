# Ensure the script is executed in a Bash shell
if [ -z "$BASH_VERSION" ]; then
    echo "${CROSSMARK} This script must be run in a Bash shell." >&2
    exit 1
fi

# === 🧠 Auto-detect PROJECT_DIR (source code root) ===

# If PROJECT_DIR is not set, attempt to find the project root (from anywhere)
if [[ -z "$PROJECT_DIR" ]]; then
    SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"

    # Go upwards from the script location to find 'config.sh'
    while [[ "$SCRIPT_PATH" != "/" ]]; do
        if [[ -f "$SCRIPT_PATH/shared/config/config.sh" ]]; then
            PROJECT_DIR="$SCRIPT_PATH"
            break
        fi
        SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
    done
fi

# === ${CHECKMARK} Load config.sh from PROJECT_DIR ===

# Check if we found the project directory and config file
if [[ -z "$PROJECT_DIR" ]]; then
    echo "${CROSSMARK} Unable to determine PROJECT_DIR. Please check the script's directory structure." >&2
    exit 1
fi

CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "${CROSSMARK} Config file not found at: $CONFIG_FILE" >&2
    exit 1
fi
source "$CONFIG_FILE"

# Import menu functions
source "$MENU_DIR/menu_utils.sh"
source "$MENU_DIR/website_management_menu.sh"
source "$MENU_DIR/wordpress_tools_menu.sh"
source "$MENU_DIR/system_tools_menu.sh"
source "$MENU_DIR/backup_menu.sh"
source "$MENU_DIR/rclone_menu.sh"
source "$MENU_DIR/ssl_menu.sh"
source "$MENU_DIR/php_menu.sh"
source "$MENU_DIR/database_menu.sh"
# **Run system setup before displaying menu**
bash "$SCRIPTS_DIR/setup-system.sh"

# ✔️ ${CROSSMARK} **Status Icons**
CHECKMARK="${GREEN}${CHECKMARK}${NC}"
CROSSMARK="${RED}${CROSSMARK}${NC}"

# 🏆 **Display Header**
print_header() {
    echo -e "\n\n\n"
    get_system_info
    echo -e "${MAGENTA}==============================================${NC}"
    echo -e "${MAGENTA}        ${CYAN}WordPress Docker 🐳            ${NC}"
    echo -e "${MAGENTA}==============================================${NC}"
    echo ""
    echo -e "${BLUE}🐳 Docker Status:${NC}"
    echo -e "  🌐 Docker Network: $(check_docker_network)"
    echo -e "  🚀 NGINX Proxy: $(check_nginx_status)"

    echo ""
    echo -e "${BLUE}📊 System Information:${NC}"
    echo -e "  🖥  CPU: ${GREEN}${CPU_MODEL} (${TOTAL_CPU} cores)${NC}"
    echo -e "  ${SAVE} RAM: ${YELLOW}${USED_RAM}MB / ${TOTAL_RAM}MB${NC}"
    echo -e "  📀 Disk: ${YELLOW}${DISK_USAGE}${NC}"
    echo -e "  🌍 IP Address: ${CYAN}${IP_ADDRESS}${NC}"
    echo ""
    # **Display current and latest versions**
    core_display_version

    echo -e "${MAGENTA}==============================================${NC}"
}

# 🎯 **Display Main Menu**
while true; do
    #core_check_for_update
    print_header
    echo -e "${BLUE}MAIN MENU:${NC}"
    echo -e "  ${GREEN}[1]${NC} WordPress Website Management    ${GREEN}[6]${NC} Website Backup Management"
    echo -e "  ${GREEN}[2]${NC} SSL Certificate Management      ${GREEN}[7]${NC} WordPress Cache Management"
    echo -e "  ${GREEN}[3]${NC} System Tools                    ${GREEN}[8]${NC} PHP Management"
    echo -e "  ${GREEN}[4]${NC} Rclone Management               ${GREEN}[9]${NC} Database Management"
    echo -e "  ${GREEN}[5]${NC} WordPress Tools                 ${GREEN}[10]${NC} Check for Updates"
    echo -e "  ${GREEN}[11]${NC} ${CROSSMARK} Exit                                                      "                                               
    echo ""

    [[ "$TEST_MODE" != true ]] && read -p "🔹 Select an option (1-10): " choice
    case "$choice" in
        1) website_management_menu ;;
        2) ssl_menu ;;
        3) system_tools_menu ;;
        4) rclone_menu ;;
        5) wordpress_tools_menu ;;
        6) backup_menu ;;
        7) bash "$MENU_DIR/wordpress/wordpress_setup_cache_menu.sh"; read -p "Press Enter to continue..." ;;
        8) php_menu ;;
        9) database_menu ;;
        10) bash "$MENU_DIR/core/core_update_menu.sh" ;;  # Call function to display version and update
        11) echo -e "${GREEN}${CROSSMARK} Exiting program.${NC}" && exit 0 ;;
        *) 
            echo -e "${RED}${WARNING} Invalid option! Please select from [1-10].${NC}"
            sleep 2 
            ;;
    esac
done
