# =====================================
# 🌍 website_management_menu.sh – WordPress Website Management Menu
# =====================================

# Load website management functions
source "$FUNCTIONS_DIR/website_loader.sh"

# Display website management menu
website_management_menu() {
  while true; do
    clear
    echo -e "${YELLOW}===== WORDPRESS WEBSITE MANAGEMENT =====${NC}"
    echo -e "${GREEN}[1]${NC} ➕ Create New Website"
    echo -e "${GREEN}[2]${NC} 🗑️ Delete Website"
    echo -e "${GREEN}[3]${NC} 📋 List Websites"
    echo -e "${GREEN}[4]${NC} 🔄 Restart Website"
    echo -e "${GREEN}[5]${NC} 📄 View Website Logs"
    echo -e "${GREEN}[6]${NC} 🔍 View Website Information"
    echo -e "${GREEN}[7]${NC} 🔄 Update Website Configuration Template"
    echo -e "${GREEN}[8]${NC} ⬅️ Back"
    echo ""

    [[ "$TEST_MODE" != true ]] && read -p "Select a function (1-7): " sub_choice
    case $sub_choice in
      1) bash "$MENU_DIR/website/website_create_menu.sh"; read -p "Press Enter to continue..." ;;
      2) bash "$MENU_DIR/website/website_delete_menu.sh"; read -p "Press Enter to continue..." ;;
      3) bash "$MENU_DIR/website/website_list_menu.sh"; read -p "Press Enter to continue..." ;;
      4) bash "$MENU_DIR/website/website_restart_menu.sh"; read -p "Press Enter to continue..." ;;
      5) bash "$MENU_DIR/website/website_logs_menu.sh"; read -p "Press Enter to continue..." ;;
      6) bash "$MENU_DIR/website/website_info_menu.sh"; read -p "Press Enter to continue..." ;;
      7) bash "$MENU_DIR/website/website_update_template_menu.sh"; read -p "Press Enter to continue..." ;;
      8) break ;;
      *) echo -e "${RED}${WARNING} Invalid option! Please select from [1-7].${NC}"; sleep 2 ;;
    esac
  done
}