#!/bin/bash

# === 🧠 Auto-detect PROJECT_DIR (project root path) ===
if [[ -z "$PROJECT_DIR" ]]; then
  SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
  while [[ "$SCRIPT_PATH" != "/" ]]; do
    if [[ -f "$SCRIPT_PATH/shared/config/config.sh" ]]; then
      PROJECT_DIR="$SCRIPT_PATH"
      break
    fi
    SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
  done
fi

# === ✅ Load config.sh from PROJECT_DIR ===
CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ config.sh not found at: $CONFIG_FILE" >&2
  exit 1
fi
source "$CONFIG_FILE"



# Function to setup Rclone
rclone_setup() {
    # Ensure configuration directory exists
    is_directory_exist "$RCLONE_CONFIG_DIR" || mkdir -p "$RCLONE_CONFIG_DIR"

    # Check if Rclone is not installed, proceed with installation
    if ! command -v rclone &> /dev/null; then
        echo -e "${YELLOW}⚠️ Rclone is not installed. Proceeding with installation...${NC}"
        
        if [[ "$(uname)" == "Darwin" ]]; then
            brew install rclone || { echo -e "${RED}❌ Error: Failed to install Rclone!${NC}"; exit 1; }
        else
            curl https://rclone.org/install.sh | sudo bash || { echo -e "${RED}❌ Error: Failed to install Rclone!${NC}"; exit 1; }
        fi

        echo -e "${GREEN}✅ Rclone installation successful!${NC}"
    else
        echo -e "${GREEN}✅ Rclone is already installed.${NC}"
    fi

    echo -e "${BLUE}🚀 Setting up Rclone Storage${NC}"

    # Check if configuration file exists
    if ! is_file_exist "$RCLONE_CONFIG_FILE"; then
        echo -e "${YELLOW}📄 Creating new Rclone configuration file: $RCLONE_CONFIG_FILE${NC}"
        touch "$RCLONE_CONFIG_FILE" || { echo -e "${RED}❌ Cannot create file $RCLONE_CONFIG_FILE${NC}"; exit 1; }
    fi

    # Enter storage name (no accents, no spaces, no special characters)
    while true; do
        [[ "$TEST_MODE" != true ]] && read -p "📌 Enter storage name (no accents, no spaces, no special characters): " STORAGE_NAME
        STORAGE_NAME=$(echo "$STORAGE_NAME" | tr '[:upper:]' '[:lower:]' | tr -d ' ' | tr -cd '[:alnum:]_-')

        if grep -q "^\[$STORAGE_NAME\]" "$RCLONE_CONFIG_FILE"; then
            echo -e "${RED}❌ Storage name '$STORAGE_NAME' already exists. Please enter a different name.${NC}"
        else
            break
        fi
    done

    # Display list of supported Rclone services
    echo -e "${GREEN}Select the type of storage you want to set up:${NC}"
    echo -e "  ${GREEN}[1]${NC} Google Drive"
    echo -e "  ${GREEN}[2]${NC} Dropbox"
    echo -e "  ${GREEN}[3]${NC} AWS S3"
    echo -e "  ${GREEN}[4]${NC} DigitalOcean Spaces"
    echo -e "  ${GREEN}[5]${NC} Exit"
    echo ""

    [[ "$TEST_MODE" != true ]] && read -p "🔹 Select an option (1-5): " choice

    case "$choice" in
        1) STORAGE_TYPE="drive" ;;
        2) STORAGE_TYPE="dropbox" ;;
        3) STORAGE_TYPE="s3" ;;
        4) STORAGE_TYPE="s3" ;;
        5) echo -e "${GREEN}❌ Exiting setup.${NC}"; return ;;
        *) echo -e "${RED}❌ Invalid option!${NC}"; return ;;
    esac

    echo -e "${BLUE}📂 Setting up Storage: $STORAGE_NAME...${NC}"

    # Save configuration to rclone.conf file
    {
        echo "[$STORAGE_NAME]"
        echo "type = $STORAGE_TYPE"
    } >> "$RCLONE_CONFIG_FILE"

    if [[ "$STORAGE_TYPE" == "drive" ]]; then
        echo -e "${YELLOW}📢 Run the following command on your computer to authorize Google Drive:${NC}"
        echo -e "${GREEN}rclone authorize drive${NC}"
        echo ""
        echo -e "${YELLOW}📌 Rclone installation guide for different operating systems:${NC}"
        echo -e "  ${GREEN}Linux:${NC} Run: ${GREEN}curl https://rclone.org/install.sh | sudo bash${NC}"
        echo -e "  ${GREEN}macOS:${NC} Run: ${GREEN}brew install rclone${NC}"
        echo -e "  ${GREEN}Windows:${NC} Download from: ${CYAN}https://rclone.org/downloads/${NC}"
        echo -e "           After installation, open Command Prompt (cmd) and run: ${GREEN}rclone authorize drive${NC}"
        echo ""
        [[ "$TEST_MODE" != true ]] && read -p "🔑 Paste OAuth JSON token here: " AUTH_JSON
        echo "token = $AUTH_JSON" >> "$RCLONE_CONFIG_FILE"

        echo -e "${GREEN}✅ Google Drive has been set up successfully!${NC}"

    elif [[ "$STORAGE_TYPE" == "dropbox" ]]; then
        echo "token = $(rclone authorize dropbox)" >> "$RCLONE_CONFIG_FILE"
    elif [[ "$STORAGE_TYPE" == "s3" ]]; then
        [[ "$TEST_MODE" != true ]] && read -p "🔑 Enter Access Key ID: " ACCESS_KEY
        [[ "$TEST_MODE" != true ]] && read -p "🔑 Enter Secret Access Key: " SECRET_KEY
        [[ "$TEST_MODE" != true ]] && read -p "🌍 Enter Region (e.g., us-east-1): " REGION

        {
            echo "provider = AWS"
            echo "access_key_id = $ACCESS_KEY"
            echo "secret_access_key = $SECRET_KEY"
            echo "region = $REGION"
        } >> "$RCLONE_CONFIG_FILE"
    fi

    echo -e "${GREEN}✅ Storage $STORAGE_NAME has been set up successfully!${NC}"
    echo -e "${GREEN}📄 Configuration saved at: $BASE_DIR/$RCLONE_CONFIG_FILE${NC}"
}

# Do not execute function by default when calling script
