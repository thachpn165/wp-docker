# =====================================
# 🌍 website_management_menu.sh – Menu quản lý website WordPress
# =====================================

# Nạp các hàm quản lý website
source "$FUNCTIONS_DIR/website/website_management_create.sh"
source "$FUNCTIONS_DIR/website/website_management_delete.sh"
source "$FUNCTIONS_DIR/website/website_management_list.sh"
source "$FUNCTIONS_DIR/website/website_management_restart.sh"
source "$FUNCTIONS_DIR/website/website_management_logs.sh"
source "$FUNCTIONS_DIR/website/website_management_info.sh"
source "$FUNCTIONS_DIR/website/website_update_site_template.sh"

# Hiển thị menu quản lý website
website_management_menu() {
  while true; do
    clear
    echo -e "${YELLOW}===== QUẢN LÝ WEBSITE WORDPRESS =====${NC}"
    echo -e "${GREEN}[1]${NC} ➕ Tạo Website Mới"
    echo -e "${GREEN}[2]${NC} 🗑️ Xóa Website"
    echo -e "${GREEN}[3]${NC} 📋 Danh Sách Website"
    echo -e "${GREEN}[4]${NC} 🔄 Restart Website"
    echo -e "${GREEN}[5]${NC} 📄 Xem Logs Website"
    echo -e "${GREEN}[6]${NC} 🔍 Xem Thông Tin Website"
    echo -e "${GREEN}[7]${NC} 🔄 Cập nhật template cấu hình Website"
    echo -e "${GREEN}[8]${NC} ⬅️ Quay lại"
    echo ""

    read -p "Chọn một chức năng (1-7): " sub_choice
    case $sub_choice in
      1) website_management_create; read -p "Nhấn Enter để tiếp tục..." ;;
      2) website_management_delete; read -p "Nhấn Enter để tiếp tục..." ;;
      3) website_management_list; read -p "Nhấn Enter để tiếp tục..." ;;
      4) website_management_restart; read -p "Nhấn Enter để tiếp tục..." ;;
      5) website_management_logs; read -p "Nhấn Enter để tiếp tục..." ;;
      6) website_management_info; read -p "Nhấn Enter để tiếp tục..." ;;
      7) website_update_site_template; read -p "Nhấn Enter để tiếp tục..." ;;
      8) break ;;
      *) echo -e "${RED}⚠️ Lựa chọn không hợp lệ! Vui lòng chọn từ [1-7].${NC}"; sleep 2 ;;
    esac
  done
}