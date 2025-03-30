# =====================================
# 🌍 website_management_menu.sh – WordPress Website Management Menu
# =====================================

# Load website management functions
source "$FUNCTIONS_DIR/website/website_management_delete.sh"
source "$FUNCTIONS_DIR/website/website_management_list.sh"
source "$FUNCTIONS_DIR/website/website_management_restart.sh"
source "$FUNCTIONS_DIR/website/website_management_logs.sh"
source "$FUNCTIONS_DIR/website/website_management_info.sh"
source "$FUNCTIONS_DIR/website/website_update_site_template.sh"

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
      2) website_management_delete; read -p "Press Enter to continue..." ;;
      3) website_management_list; read -p "Press Enter to continue..." ;;
      4) website_management_restart; read -p "Press Enter to continue..." ;;
      5) website_management_logs; read -p "Press Enter to continue..." ;;
      6) website_management_info; read -p "Press Enter to continue..." ;;
      7) website_update_site_template; read -p "Press Enter to continue..." ;;
      8) break ;;
      *) echo -e "${RED}⚠️ Invalid option! Please select from [1-7].${NC}"; sleep 2 ;;
    esac
  done
}