# 🌍 **Hiển thị menu quản lý website**
manage_website_menu() {
    while true; do
        clear
        echo -e "${YELLOW}===== QUẢN LÝ WEBSITE WORDPRESS =====${NC}"
        echo -e "${GREEN}[1]${NC} ➕ Tạo Website Mới"
        echo -e "${GREEN}[2]${NC} 🗑️ Xóa Website"
        echo -e "${GREEN}[3]${NC} 📋 Danh Sách Website"
        echo -e "${GREEN}[4]${NC} 🔄 Restart Website"
        echo -e "${GREEN}[5]${NC} 📄 Xem Logs Website"
        echo -e "${GREEN}[6]${NC} ⬅️ Quay lại"
        echo ""

        read -p "Chọn một chức năng (1-6): " sub_choice
        case $sub_choice in
            1) bash "$WEBSITE_MGMT_DIR/create-website.sh"; read -p "Nhấn Enter để tiếp tục..." ;;
            2) bash "$WEBSITE_MGMT_DIR/delete-website.sh"; read -p "Nhấn Enter để tiếp tục..." ;;
            3) bash "$WEBSITE_MGMT_DIR/list-websites.sh"; read -p "Nhấn Enter để tiếp tục..." ;;
            4) bash "$WEBSITE_MGMT_DIR/restart-website.sh"; read -p "Nhấn Enter để tiếp tục..." ;;
            5) bash "$WEBSITE_MGMT_DIR/logs-website.sh"; read -p "Nhấn Enter để tiếp tục..." ;;
            6) break ;;
            *) 
                echo -e "${RED}⚠️ Lựa chọn không hợp lệ! Vui lòng chọn từ [1-6].${NC}"
                sleep 2 
                ;;
        esac
    done
}