# 📌 Get total RAM capacity (MB), works on both Linux & macOS
get_total_ram() {
    if command -v free >/dev/null 2>&1; then
        free -m | awk '/^Mem:/{print $2}'
    else
        sysctl -n hw.memsize | awk '{print $1 / 1024 / 1024}'
    fi
}

# 📌 Get total CPU cores, works on both Linux & macOS
get_total_cpu() {
    if command -v nproc >/dev/null 2>&1; then
        nproc
    else
        sysctl -n hw.ncpu
    fi
}

# 🧩 macOS/Linux compatible sed function
sedi() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# Check and set Vietnam timezone on the server
setup_timezone() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        current_tz=$(timedatectl | grep "Time zone" | awk '{print $3}')
        if [[ "$current_tz" != "Asia/Ho_Chi_Minh" ]]; then
            echo -e "${YELLOW}🌏 Setting system timezone to Asia/Ho_Chi_Minh...${NC}"
            timedatectl set-timezone Asia/Ho_Chi_Minh
            echo -e "${GREEN}✅ System timezone has been changed.${NC}"
        fi
    fi
}

# Function to choose text editor for file editing
choose_editor() {
  echo -e "${CYAN}🛠️ Checking available text editors...${NC}"

  AVAILABLE_EDITORS=()
  [[ -x "$(command -v nano)" ]] && AVAILABLE_EDITORS+=("nano")
  [[ -x "$(command -v vi)" ]] && AVAILABLE_EDITORS+=("vi")
  [[ -x "$(command -v vim)" ]] && AVAILABLE_EDITORS+=("vim")
  [[ -x "$(command -v micro)" ]] && AVAILABLE_EDITORS+=("micro")
  [[ -x "$(command -v code)" ]] && AVAILABLE_EDITORS+=("code")

  if [[ ${#AVAILABLE_EDITORS[@]} -eq 0 ]]; then
    echo -e "${RED}❌ No text editors found! Please install nano or vim first.${NC}"
    return 1
  fi

  echo -e "${YELLOW}📋 Available text editors:${NC}"
  for i in "${!AVAILABLE_EDITORS[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${AVAILABLE_EDITORS[$i]}"
  done

  [[ "$TEST_MODE" != true ]] && read -p "🔹 Select number corresponding to text editor: " editor_index

  if ! [[ "$editor_index" =~ ^[0-9]+$ ]] || (( editor_index < 0 || editor_index >= ${#AVAILABLE_EDITORS[@]} )); then
    echo -e "${RED}⚠️ Invalid selection! Defaulting to nano if available.${NC}"
    EDITOR_CMD="nano"
  else
    EDITOR_CMD="${AVAILABLE_EDITORS[$editor_index]}"
  fi

  echo -e "${CYAN}📘 ${EDITOR_CMD} Usage Guide:${NC}"
  case "$EDITOR_CMD" in
    nano)
      echo -e "  🖋️  Ctrl + O → Save file"
      echo -e "  ❌  Ctrl + X → Exit"
      ;;
    vi|vim)
      echo -e "  🖋️  Press 'i' → Enter edit mode"
      echo -e "  💾  ESC → Type :w to save"
      echo -e "  ❌  ESC → Type :q to exit"
      ;;
    micro)
      echo -e "  🖋️  Ctrl + S → Save file"
      echo -e "  ❌  Ctrl + Q → Exit"
      ;;
    code)
      echo -e "  💡 Opens Visual Studio Code in GUI mode"
      echo -e "  🔁 Auto-saves on changes (if enabled)"
      ;;
    *)
      echo -e "${YELLOW}⚠️ Unknown editor, you'll handle the operations yourself :)${NC}"
      ;;
  esac

  echo ""
  [[ "$TEST_MODE" != true ]] && read -p "❓ Would you like to start editing with ${EDITOR_CMD}? [Y/n]: " confirm
  if [[ "$confirm" =~ ^[Nn]$ ]]; then
    echo -e "${YELLOW}⏩ Edit operation cancelled.${NC}"
    return 1
  fi

  return 0
}

# Function to check and install required commands
check_required_commands() {
    echo -e "${YELLOW}🔍 Checking required commands...${NC}"

    # List of required commands
    required_cmds=(docker "docker compose" nano rsync curl tar gzip unzip jq openssl crontab dialog)

    for cmd in "${required_cmds[@]}"; do
        # Special case: check if docker compose is a plugin
        if [[ "$cmd" == "docker compose" ]]; then
            if docker compose version &> /dev/null; then
                echo -e "${GREEN}✅ 'docker compose' is available.${NC}"
                continue
            else
                echo -e "${YELLOW}⚠️ 'docker compose' is not installed. Installing...${NC}"
                install_docker_compose
                continue
            fi
        fi

        if ! command -v $(echo "$cmd" | awk '{print $1}') &> /dev/null; then
            echo -e "${YELLOW}⚠️ Command '$cmd' is not installed. Installing...${NC}"

            if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                if command -v apt &> /dev/null; then
                    apt update -y && apt install -y $(echo "$cmd" | awk '{print $1}')
                elif command -v yum &> /dev/null; then
                    yum install -y $(echo "$cmd" | awk '{print $1}')
                elif command -v dnf &> /dev/null; then
                    dnf install -y $(echo "$cmd" | awk '{print $1}')
                else
                    echo -e "${RED}❌ No suitable package manager found to install '$cmd'.${NC}"
                fi
            elif [[ "$OSTYPE" == "darwin"* ]]; then
                if ! command -v brew &> /dev/null; then
                    echo -e "${YELLOW}🍺 Homebrew is not installed. Installing Homebrew...${NC}"
                    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                fi
                brew install $(echo "$cmd" | awk '{print $1}')
            else
                echo -e "${RED}❌ Operating system not supported for installing '$cmd'.${NC}"
            fi
        else
            echo -e "${GREEN}✅ Command '$cmd' is available.${NC}"
        fi
    done
}
