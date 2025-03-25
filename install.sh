#!/bin/bash

# =====================================
# 🧩 install.sh – Cài đặt WP Docker LEMP từ GitHub
# =====================================

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

set -euo pipefail

REPO_URL="https://github.com/thachpn165/wp-docker-lemp"
BRANCH="main"
INSTALL_DIR="$HOME/wp-docker-lemp"

# 🧹 Xóa nếu thư mục đã tồn tại tạm thời
TMP_DIR="/tmp/wp-docker-install"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

# 📦 Cài đặt các package cần thiết
install_dependencies() {
  echo -e "${CYAN}🔧 Đang kiểm tra và cài đặt các gói phụ thuộc...${NC}"

  # Kiểm tra docker
  if command -v docker &>/dev/null; then
    echo -e "${GREEN}✅ Đã có Docker${NC}"
  else
    echo -e "${YELLOW}❌ Docker chưa được cài, đang tiến hành cài đặt...${NC}"
    if command -v apt &>/dev/null; then
      sudo apt update
      sudo apt install -y docker.io
    elif command -v yum &>/dev/null; then
      sudo yum install -y docker
    fi
  fi

  # Kiểm tra docker compose plugin
  if docker compose version &>/dev/null; then
    echo -e "${GREEN}✅ Đã có Docker Compose (plugin)${NC}"
  else
    echo -e "${YELLOW}❌ Docker Compose plugin chưa có, đang tiến hành cài đặt...${NC}"
    DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
    mkdir -p "$DOCKER_CONFIG/cli-plugins"
    ARCH=$(uname -m)
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    curl -SL "https://github.com/docker/compose/releases/download/v2.34.0/docker-compose-${OS}-${ARCH}" \
      -o "$DOCKER_CONFIG/cli-plugins/docker-compose"
    chmod +x "$DOCKER_CONFIG/cli-plugins/docker-compose"
    echo -e "${GREEN}✅ Đã cài Docker Compose plugin vào $DOCKER_CONFIG/cli-plugins${NC}"
  fi

  # Các gói cơ bản khác
  for pkg in curl unzip git openssl nano; do
    if ! command -v $pkg &>/dev/null; then
      echo -e "${YELLOW}❌ Gói $pkg chưa có, đang tiến hành cài đặt...${NC}"
      if command -v apt &>/dev/null; then
        sudo apt install -y $pkg
      elif command -v yum &>/dev/null; then
        sudo yum install -y $pkg
      elif [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &>/dev/null; then
          brew install $pkg
        else
          echo -e "${RED}⚠️ Không thể cài $pkg vì thiếu Homebrew trên macOS.${NC}"
        fi
      fi
    else
      echo -e "${GREEN}✅ Đã có $pkg${NC}"
    fi
  done

  # Đặc biệt với macOS
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v brew &>/dev/null; then
      echo -e "${RED}🍺 Homebrew chưa được cài đặt. Vui lòng cài đặt tại: https://brew.sh${NC}"
      exit 1
    fi
    echo -e "${CYAN}✅ Hệ điều hành macOS - đang kiểm tra Docker Desktop...${NC}"
    if ! docker compose version &>/dev/null; then
      echo -e "${RED}⚠️ Vui lòng cài Docker Desktop để sử dụng Docker Compose trên macOS${NC}"
      exit 1
    fi
  fi
}

install_dependencies

# 📥 Tải source từ GitHub
echo -e "${CYAN}📥 Đang tải WP Docker LEMP từ GitHub...${NC}"
curl -L "$REPO_URL/archive/refs/heads/$BRANCH.zip" -o "$TMP_DIR/source.zip"
unzip -q "$TMP_DIR/source.zip" -d "$TMP_DIR"

# 🚀 Di chuyển vào thư mục cài đặt
EXTRACTED_DIR="$TMP_DIR/wp-docker-lemp-$BRANCH"

# ⚠️ Nếu thư mục đã tồn tại thì hỏi người dùng
if [[ -d "$INSTALL_DIR" ]]; then
  echo -e "${YELLOW}⚠️ Thư mục $INSTALL_DIR đã tồn tại.${NC}"
  read -rp "❓ Bạn có muốn xoá để cài lại không? [y/N]: " confirm
  if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
    echo -e "${MAGENTA}🗑️ Đang xoá thư mục cũ...${NC}"
    rm -rf "$INSTALL_DIR"
  else
    echo -e "${RED}❌ Huỷ cài đặt. Bạn có thể xoá thủ công thư mục $INSTALL_DIR rồi chạy lại.${NC}"
    exit 1
  fi
fi

mv "$EXTRACTED_DIR" "$INSTALL_DIR"

# 🔖 Ghi phiên bản hiện tại
cp "$INSTALL_DIR/version.txt" "$INSTALL_DIR/shared/VERSION"

# ✅ Hiển thị thông tin kết thúc
cd "$INSTALL_DIR"
echo -e "\n${GREEN}✅ Đã cài đặt thành công tại: ${YELLOW}$INSTALL_DIR${NC}"
echo -e "\n👉 Bạn có thể bắt đầu sử dụng hệ thống bằng lệnh sau:\n"
echo -e "   ${YELLOW}cd $INSTALL_DIR && bash ./main.sh${NC}"
echo -e "\n🚀 Chúc bạn sử dụng hiệu quả WP Docker LEMP Stack!"