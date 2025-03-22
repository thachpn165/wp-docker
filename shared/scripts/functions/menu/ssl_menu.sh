#!/bin/bash

# Load cấu hình
CONFIG_FILE="shared/config/config.sh"
while [ ! -f "$CONFIG_FILE" ]; do
    CONFIG_FILE="../$CONFIG_FILE"
    if [ "$(pwd)" = "/" ]; then
        echo "❌ Lỗi: Không tìm thấy config.sh!" >&2
        exit 1
    fi
done
source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/ssl/ssl_generate_self_signed.sh"

# Header menu
print_ssl_menu_header() {
    echo -e "\n${MAGENTA}===========================================${NC}"
    echo -e "         🔐 QUẢN LÝ CHỨNG CHỈ SSL"
    echo -e "${MAGENTA}===========================================${NC}"
}

# Hiển thị menu
ssl_menu() {
    while true; do
        print_ssl_menu_header
        echo -e "${GREEN}1)${NC} Tạo chứng chỉ tự ký (Self-signed)"
        echo -e "${GREEN}2)${NC} Cài đặt chứng chỉ thủ công (.crt/.key)"
        echo -e "${GREEN}3)${NC} Sửa chứng chỉ SSL hiện tại"
        echo -e "${GREEN}4)${NC} Cài chứng chỉ Let's Encrypt (miễn phí)"
        echo -e "${GREEN}5)${NC} Kiểm tra trạng thái chứng chỉ SSL"
        echo -e "${GREEN}6)${NC} Danh sách domain đã có SSL"
        echo -e "${GREEN}7)${NC} Quay lại menu chính"
        echo ""

        read -p "🔹 Chọn một tùy chọn (1-7): " choice
        case "$choice" in
            1)
                ssl_generate_self_signed
                read -p "Nhấn Enter để tiếp tục..."
                ;;
            2)
                echo -e "\n🛠️ [ĐANG PHÁT TRIỂN] Cài chứng chỉ thủ công"
                read -p "Nhấn Enter để tiếp tục..."
                ;;
            3)
                echo -e "\n🛠️ [ĐANG PHÁT TRIỂN] Sửa chứng chỉ SSL"
                read -p "Nhấn Enter để tiếp tục..."
                ;;
            4)
                echo -e "\n🛠️ [ĐANG PHÁT TRIỂN] Cài Let's Encrypt"
                read -p "Nhấn Enter để tiếp tục..."
                ;;
            5)
                echo -e "\n🛠️ [ĐANG PHÁT TRIỂN] Kiểm tra trạng thái SSL"
                read -p "Nhấn Enter để tiếp tục..."
                ;;
            6)
                echo -e "\n🛠️ [ĐANG PHÁT TRIỂN] Danh sách domain có SSL"
                read -p "Nhấn Enter để tiếp tục..."
                ;;
            7)
                break
                ;;
            *)
                echo -e "${RED}⚠️ Lựa chọn không hợp lệ. Vui lòng thử lại.${NC}"
                sleep 1
                ;;
        esac
    done
}
