#!/bin/bash
# Chạy wpdocker từ bất kỳ nơi nào

INSTALL_DIR="/opt/wp-docker"
MAIN_SCRIPT="$INSTALL_DIR/main.sh"

if [ ! -f "$MAIN_SCRIPT" ]; then
  echo "❌ Không tìm thấy main.sh tại $MAIN_SCRIPT"
  exit 1
fi

# Thiết lập BASE_DIR để các script khác dùng đúng đường
export BASE_DIR="$INSTALL_DIR"
cd "$INSTALL_DIR"

bash "$MAIN_SCRIPT" "$@"
