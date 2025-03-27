# 📌 Lấy tổng dung lượng RAM (MB), hoạt động trên cả Linux & macOS
get_total_ram() {
    if command -v free >/dev/null 2>&1; then
        free -m | awk '/^Mem:/{print $2}'
    else
        sysctl -n hw.memsize | awk '{print $1 / 1024 / 1024}'
    fi
}

# 📌 Lấy tổng số CPU core, hoạt động trên cả Linux & macOS
get_total_cpu() {
    if command -v nproc >/dev/null 2>&1; then
        nproc
    else
        sysctl -n hw.ncpu
    fi
}

# 🧩 Hàm xử lý sed tương thích macOS/Linux
sedi() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# Kiểm tra và thiết lập múi giờ của Việt Nam trên máy chủ
setup_timezone() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        current_tz=$(timedatectl | grep "Time zone" | awk '{print $3}')
        if [[ "$current_tz" != "Asia/Ho_Chi_Minh" ]]; then
            echo -e "${YELLOW}🌏 Đặt múi giờ hệ thống về Asia/Ho_Chi_Minh...${NC}"
            sudo timedatectl set-timezone Asia/Ho_Chi_Minh
            echo -e "${GREEN}✅ Đã đổi múi giờ hệ thống.${NC}"
        fi
    fi
}

# Hàm chọn trình soạn thảo để sửa file
choose_editor() {
  echo -e "${CYAN}🛠️ Đang kiểm tra trình soạn thảo khả dụng...${NC}"

  AVAILABLE_EDITORS=()
  [[ -x "$(command -v nano)" ]] && AVAILABLE_EDITORS+=("nano")
  [[ -x "$(command -v vi)" ]] && AVAILABLE_EDITORS+=("vi")
  [[ -x "$(command -v vim)" ]] && AVAILABLE_EDITORS+=("vim")
  [[ -x "$(command -v micro)" ]] && AVAILABLE_EDITORS+=("micro")
  [[ -x "$(command -v code)" ]] && AVAILABLE_EDITORS+=("code")

  if [[ ${#AVAILABLE_EDITORS[@]} -eq 0 ]]; then
    echo -e "${RED}❌ Không tìm thấy trình soạn thảo nào! Vui lòng cài nano hoặc vim trước.${NC}"
    return 1
  fi

  echo -e "${YELLOW}📋 Danh sách trình soạn thảo khả dụng:${NC}"
  for i in "${!AVAILABLE_EDITORS[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${AVAILABLE_EDITORS[$i]}"
  done

  read -p "🔹 Chọn số tương ứng với trình soạn thảo: " editor_index

  if ! [[ "$editor_index" =~ ^[0-9]+$ ]] || (( editor_index < 0 || editor_index >= ${#AVAILABLE_EDITORS[@]} )); then
    echo -e "${RED}⚠️ Lựa chọn không hợp lệ! Mặc định dùng nano nếu có.${NC}"
    EDITOR_CMD="nano"
  else
    EDITOR_CMD="${AVAILABLE_EDITORS[$editor_index]}"
  fi

  echo -e "${CYAN}📘 Hướng dẫn sử dụng ${EDITOR_CMD}:${NC}"
  case "$EDITOR_CMD" in
    nano)
      echo -e "  🖋️  Ctrl + O → Lưu file"
      echo -e "  ❌  Ctrl + X → Thoát"
      ;;
    vi|vim)
      echo -e "  🖋️  Nhấn 'i' → Chế độ sửa"
      echo -e "  💾  ESC → Nhập :w để lưu"
      echo -e "  ❌  ESC → Nhập :q để thoát"
      ;;
    micro)
      echo -e "  🖋️  Ctrl + S → Lưu file"
      echo -e "  ❌  Ctrl + Q → Thoát"
      ;;
    code)
      echo -e "  💡 Mở Visual Studio Code trong chế độ đồ hoạ"
      echo -e "  🔁 Tự lưu khi thay đổi (nếu bật)"
      ;;
    *)
      echo -e "${YELLOW}⚠️ Trình soạn thảo không rõ, bạn tự xử lý thao tác nhé :)${NC}"
      ;;
  esac

  echo ""
  read -p "❓ Bạn có muốn bắt đầu sửa file bằng ${EDITOR_CMD}? [Y/n]: " confirm
  if [[ "$confirm" =~ ^[Nn]$ ]]; then
    echo -e "${YELLOW}⏩ Đã huỷ thao tác chỉnh sửa.${NC}"
    return 1
  fi

  return 0
}

# Hàm kiểm tra và cài đặt các lệnh cần thiết
check_required_commands() {
    echo -e "${YELLOW}🔍 Đang kiểm tra các lệnh cần thiết...${NC}"

    # Danh sách các lệnh cần thiết
    required_cmds=(docker "docker compose" nano rsync curl tar gzip unzip jq openssl crontab dialog)

    for cmd in "${required_cmds[@]}"; do
        # Trường hợp đặc biệt: kiểm tra docker compose là plugin
        if [[ "$cmd" == "docker compose" ]]; then
            if docker compose version &> /dev/null; then
                echo -e "${GREEN}✅ 'docker compose' đã có sẵn.${NC}"
                continue
            else
                echo -e "${YELLOW}⚠️ 'docker compose' chưa được cài đặt. Đang tiến hành cài đặt...${NC}"
                install_docker_compose
                continue
            fi
        fi

        if ! command -v $(echo "$cmd" | awk '{print $1}') &> /dev/null; then
            echo -e "${YELLOW}⚠️ Lệnh '$cmd' chưa được cài đặt. Đang tiến hành cài đặt...${NC}"

            if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                if command -v apt &> /dev/null; then
                    sudo apt update -y && sudo apt install -y $(echo "$cmd" | awk '{print $1}')
                elif command -v yum &> /dev/null; then
                    sudo yum install -y $(echo "$cmd" | awk '{print $1}')
                elif command -v dnf &> /dev/null; then
                    sudo dnf install -y $(echo "$cmd" | awk '{print $1}')
                else
                    echo -e "${RED}❌ Không tìm thấy trình quản lý gói phù hợp để cài đặt '$cmd'.${NC}"
                fi
            elif [[ "$OSTYPE" == "darwin"* ]]; then
                if ! command -v brew &> /dev/null; then
                    echo -e "${YELLOW}🍺 Homebrew chưa được cài. Đang cài đặt Homebrew...${NC}"
                    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                fi
                brew install $(echo "$cmd" | awk '{print $1}')
            else
                echo -e "${RED}❌ Hệ điều hành không được hỗ trợ để cài '$cmd'.${NC}"
            fi
        else
            echo -e "${GREEN}✅ Lệnh '$cmd' đã có sẵn.${NC}"
        fi
    done
}
