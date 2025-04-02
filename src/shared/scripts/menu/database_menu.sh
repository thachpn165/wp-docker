#!/bin/bash

# === 🧠 Auto-detect PROJECT_DIR (source code root) ===

if [[ -z "$PROJECT_DIR" ]]; then
    SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
    while [[ "$SCRIPT_PATH" != "/" && ! -f "$SCRIPT_PATH/shared/config/config.sh" ]]; do
        SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
    done
    PROJECT_DIR="$SCRIPT_PATH"
fi

CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "${CROSSMARK} Config file not found at: $CONFIG_FILE" >&2
    exit 1
fi
source "$CONFIG_FILE"

# Function to display backup management menu
database_menu() {
    while true; do
        echo -e "${BLUE}============================${NC}"
        echo -e "${BLUE}   DATABASE MANAGEMENT      ${NC}"
        echo -e "${BLUE}============================${NC}"
        echo -e "  ${GREEN}[1]${NC} Reset Database (DANGER ☢️)"
        echo -e "  ${GREEN}[2]${NC} Export Database"
        echo -e "  ${GREEN}[3]${NC} Import Database"
        echo -e "  ${GREEN}[6]${NC} ${CROSSMARK} Exit"
        echo -e "${BLUE}============================${NC}"
        
        [[ "$TEST_MODE" != true ]] && read -p "🔹 Select an option (1-6): " choice

        case "$choice" in
            1) bash "$MENU_DIR/database/database_reset_menu.sh" ;;
            2) bash "$MENU_DIR/database/database_export_menu.sh" ;;
            3) bash "$MENU_DIR/database/database_import_menu.sh" ;;
            6) 
                echo -e "${GREEN}👋 Exiting Database menu!${NC}"
                break
                ;;
            *)
                echo -e "${RED}${CROSSMARK} Invalid option, please try again!${NC}"
                ;;
        esac
    done
}
