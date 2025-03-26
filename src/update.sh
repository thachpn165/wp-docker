# =====================================
# 🔄 update.sh – Cập nhật từ GitHub
# =====================================

# Kiểm tra phiên bản hiện tại
VERSION_FILE="$INSTALL_DIR/version.txt"
LATEST_VERSION_URL="$REPO_RAW/main/version.txt"

if [ ! -f "$VERSION_FILE" ]; then
    echo "⚠️ Không tìm thấy version.txt hiện tại."
    exit 1
fi

CURRENT_VERSION=$(cat "$VERSION_FILE")
LATEST_VERSION=$(curl -s "$LATEST_VERSION_URL")

echo "🔍 Phiên bản hiện tại: $CURRENT_VERSION"
echo "🌐 Phiên bản mới nhất: $LATEST_VERSION"

if [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]]; then
    echo "✅ Bạn đang sử dụng phiên bản mới nhất."
    exit 0
fi

read -p "⚠️ Có phiên bản mới. Bạn có muốn cập nhật không? [Y/n]: " confirm
confirm=${confirm,,}
if [[ "$confirm" != "y" && "$confirm" != "" ]]; then
    echo "❌ Đã huỷ cập nhật."
    exit 0
fi

# Tiến hành cập nhật
cd "$HOME"
echo "⬇️ Đang tải phiên bản mới..."
git clone --depth=1 "$REPO_URL" wp-docker-lemp-tmp

if [ ! -d "wp-docker-lemp-tmp" ]; then
    echo "❌ Không thể tải về mã nguồn mới."
    exit 1
fi

# Ghi đè source cũ (trừ sites/, logs/,...)
echo "🔄 Đang cập nhật..."
rsync -a --delete \
    --exclude="sites" \
    --exclude="logs" \
    --exclude="tmp" \
    --exclude="version.txt" \
    wp-docker-lemp-tmp/ "$INSTALL_DIR/"

# Ghi đè version.txt mới
echo "$LATEST_VERSION" > "$INSTALL_DIR/version.txt"

# Xoá thư mục tạm
rm -rf wp-docker-lemp-tmp

echo "✅ Đã cập nhật lên phiên bản mới nhất: $LATEST_VERSION"