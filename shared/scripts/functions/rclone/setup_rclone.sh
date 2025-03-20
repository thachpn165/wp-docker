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

RCLONE_CONFIG_DIR="shared/config/rclone"
RCLONE_CONFIG_FILE="$RCLONE_CONFIG_DIR/rclone.conf"

# Đảm bảo thư mục cấu hình tồn tại
is_directory_exist "$RCLONE_CONFIG_DIR"

# Kiểm tra xem Rclone đã được cài đặt chưa
if ! command -v rclone &> /dev/null; then
    echo -e "${YELLOW}⚠️ Rclone chưa được cài đặt. Tiến hành cài đặt...${NC}"
    
    # Xác định hệ điều hành và cài đặt Rclone
    if [[ "$(uname)" == "Darwin" ]]; then
        echo -e "${BLUE}🍏 Đang cài đặt Rclone trên macOS...${NC}"
        brew install rclone || { echo -e "${RED}❌ Lỗi: Cài đặt Rclone thất bại!${NC}"; exit 1; }
    else
        echo -e "${BLUE}🐧 Đang cài đặt Rclone trên Linux...${NC}"
        curl https://rclone.org/install.sh | sudo bash || { echo -e "${RED}❌ Lỗi: Cài đặt Rclone thất bại!${NC}"; exit 1; }
    fi

    echo -e "${GREEN}✅ Cài đặt Rclone thành công!${NC}"
else
    echo -e "${GREEN}✅ Rclone đã được cài đặt.${NC}"
fi

echo -e "${BLUE}🚀 Thiết lập Rclone cho backup tự động${NC}"

# Kiểm tra nếu tập tin cấu hình đã tồn tại
if is_file_exist "$RCLONE_CONFIG_FILE"; then
    echo -e "${YELLOW}⚠️ Đã có cấu hình Rclone trong $RCLONE_CONFIG_FILE${NC}"
    read -p "Bạn có muốn tiếp tục không? (y/n): " confirm
    [[ "$confirm" != "y" ]] && exit 0
else
    echo -e "${YELLOW}📄 Tạo mới tập tin cấu hình Rclone: $RCLONE_CONFIG_FILE${NC}"
    touch "$RCLONE_CONFIG_FILE"
fi

echo -e "${BLUE}🚀 Thiết lập Storage cho Rclone${NC}"

# Hiển thị danh sách các dịch vụ Rclone hỗ trợ
echo -e "${GREEN}Chọn loại storage bạn muốn thiết lập:${NC}"
echo -e "  ${GREEN}[1]${NC} Google Drive"
echo -e "  ${GREEN}[2]${NC} Dropbox"
echo -e "  ${GREEN}[3]${NC} AWS S3"
echo -e "  ${GREEN}[4]${NC} DigitalOcean Spaces"
echo -e "  ${GREEN}[5]${NC} Thoát"
echo ""

read -p "🔹 Chọn một tùy chọn (1-5): " choice

case "$choice" in
    1) STORAGE_NAME="google_drive"; STORAGE_TYPE="drive" ;;
    2) STORAGE_NAME="dropbox"; STORAGE_TYPE="dropbox" ;;
    3) STORAGE_NAME="aws_s3"; STORAGE_TYPE="s3" ;;
    4) STORAGE_NAME="do_spaces"; STORAGE_TYPE="s3" ;;
    5) echo -e "${GREEN}❌ Thoát khỏi cài đặt.${NC}"; exit 0 ;;
    *) echo -e "${RED}❌ Lựa chọn không hợp lệ!${NC}"; exit 1 ;;
esac

echo -e "${BLUE}📂 Đang thiết lập Storage: $STORAGE_NAME...${NC}"

# Tạo cấu hình mới trong rclone.conf
echo "[$STORAGE_NAME]" >> "$RCLONE_CONFIG_FILE"
echo "type = $STORAGE_TYPE" >> "$RCLONE_CONFIG_FILE"

if [[ "$STORAGE_TYPE" == "drive" ]]; then
    echo -e "${YELLOW}📢 Hãy chạy lệnh sau trên máy tính của bạn để cấp quyền Google Drive:${NC}"
    echo -e "${GREEN}rclone authorize drive${NC}"
    echo ""
    echo -e "${YELLOW}📌 Hướng dẫn cài đặt Rclone trên các hệ điều hành:${NC}"
    echo -e "  ${GREEN}Linux:${NC} Chạy lệnh: ${GREEN}curl https://rclone.org/install.sh | sudo bash${NC}"
    echo -e "  ${GREEN}macOS:${NC} Chạy lệnh: ${GREEN}brew install rclone${NC}"
    echo -e "  ${GREEN}Windows:${NC} Tải tại: ${CYAN}https://rclone.org/downloads/${NC}"
    echo -e "           Sau khi cài đặt, mở Command Prompt (cmd) và chạy: ${GREEN}rclone authorize drive${NC}"
    echo ""
    read -p "🔑 Dán mã xác thực OAuth JSON tại đây: " AUTH_JSON
    echo "token = $AUTH_JSON" >> "$RCLONE_CONFIG_FILE"

    echo -e "${GREEN}✅ Google Drive đã được thiết lập thành công!${NC}"

elif [[ "$STORAGE_TYPE" == "dropbox" ]]; then
    echo "token = $(rclone authorize dropbox)" >> "$RCLONE_CONFIG_FILE"
elif [[ "$STORAGE_TYPE" == "s3" ]]; then
    read -p "🔑 Nhập Access Key ID: " ACCESS_KEY
    read -p "🔑 Nhập Secret Access Key: " SECRET_KEY
    read -p "🌍 Nhập Region (VD: us-east-1): " REGION

    echo "provider = AWS" >> "$RCLONE_CONFIG_FILE"
    echo "access_key_id = $ACCESS_KEY" >> "$RCLONE_CONFIG_FILE"
    echo "secret_access_key = $SECRET_KEY" >> "$RCLONE_CONFIG_FILE"
    echo "region = $REGION" >> "$RCLONE_CONFIG_FILE"
fi

echo -e "${GREEN}✅ Storage $STORAGE_NAME đã được thiết lập thành công!${NC}"
echo -e "${GREEN}📄 Cấu hình được lưu tại: $RCLONE_CONFIG_FILE${NC}"