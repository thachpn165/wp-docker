#!/bin/bash

CONFIG_FILE="shared/config/config.sh"

# Xác định đường dẫn tuyệt đối của `config.sh`
while [ ! -f "$CONFIG_FILE" ]; do
    CONFIG_FILE="../$CONFIG_FILE"
    if [ "$(pwd)" = "/" ]; then
        echo "❌ Lỗi: Không tìm thấy config.sh!" >&2
        exit 1
    fi
done

source "$CONFIG_FILE"

# Import các hàm Rclone
source "$SCRIPTS_FUNCTIONS_DIR/rclone/setup_rclone.sh"
source "$SCRIPTS_FUNCTIONS_DIR/rclone/upload_backup.sh"
source "$SCRIPTS_FUNCTIONS_DIR/rclone/manage_rclone.sh"

# Hàm hiển thị menu quản lý Rclone
rclone_menu() {
    while true; do
        echo -e "${BLUE}============================${NC}"
        echo -e "${BLUE}   📤 QUẢN LÝ RCLONE   ${NC}"
        echo -e "${BLUE}============================${NC}"
        echo -e "  ${GREEN}[1]${NC} 🚀 Thiết lập Rclone"
        echo -e "  ${GREEN}[2]${NC} 📂 Upload Backup lên Storage"
        echo -e "  ${GREEN}[3]${NC} 🔍 Xem danh sách Storage"
        echo -e "  ${GREEN}[4]${NC} 🗑️ Xóa Storage đã thiết lập"
        echo -e "  ${GREEN}[5]${NC} ❌ Thoát"
        echo -e "${BLUE}============================${NC}"
        
        read -p "🔹 Chọn một tùy chọn (1-5): " choice

        case "$choice" in
            1) setup_rclone ;;
            2) bash "$SCRIPTS_FUNCTIONS_DIR/rclone/upload_backup.sh" ;;
            3) echo ""
                echo "Danh sách storage khả dụng"
                echo ""
                rclone_storage_list 
                echo "";;
                
            4) rclone_storage_delete ;;
            5) echo -e "${GREEN}👋 Thoát khỏi menu Rclone!${NC}"; break ;;
            *) echo -e "${RED}❌ Lựa chọn không hợp lệ, vui lòng nhập lại!${NC}" ;;
        esac
    done
}
