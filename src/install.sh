if [ "$EUID" -ne 0 ]; then
  echo "⚠️ Please run this script as root or with sudo."
  exit 1
fi

#!/bin/bash

INSTALL_DIR="/opt/wp-docker"
BIN_NAME="wpdocker"
BIN_LINK="/usr/local/bin/$BIN_NAME"
REPO_URL="https://github.com/thachpn165/wp-docker"
ZIP_NAME="wp-docker.zip"
DEV_MODE=false

# ========================
# ⚙️ Command Line Parameter Processing
# ========================
if [[ "$1" == "--dev" ]]; then
  DEV_MODE=true
  echo "🛠 Installing in DEV mode (no system symlink creation)"
fi

# ========================
# 🧹 Check if directory exists
# ========================
if [[ -d "$INSTALL_DIR" ]]; then
  echo "⚠️ Directory $INSTALL_DIR already exists."
  read -rp "❓ Do you want to delete and overwrite it? [y/N]: " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "❌ Installation cancelled."
    exit 0
  fi
  rm -rf "$INSTALL_DIR"
fi

# ========================
# 📥 Download and extract release
# ========================
echo "📦 Downloading source code from GitHub Release..."
curl -L "$REPO_URL/releases/latest/download/wp-docker.zip" -o "$ZIP_NAME" || { echo "❌ Command failed at line 35"; exit 1; }

echo "📁 Extracting to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
unzip -q "$ZIP_NAME" -d "$INSTALL_DIR"
rm "$ZIP_NAME" || { echo "❌ Command failed at line 40"; exit 1; }

# ========================
# ✅ Set permissions for current user
# ========================
echo "🔐 Setting permissions for user: $USER"
chown -R "$USER" "$INSTALL_DIR"

# ========================
# 🔗 Create global alias if not in dev mode
# ========================
chmod +x "$INSTALL_DIR/shared/bin/$BIN_NAME.sh"

if [[ "$DEV_MODE" != true ]]; then
  ln -sf "$INSTALL_DIR/shared/bin/$BIN_NAME.sh" "$BIN_LINK"
  echo "✅ Created '$BIN_NAME' command for running from anywhere."
fi

echo "✅ Installation successful at: $INSTALL_DIR"
echo "👉 You can run the system using: $BIN_NAME"

# ========================
# 📢 Special warning for macOS (Docker Desktop)
# ========================
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo ""
  echo "⚠️  ${YELLOW}IMPORTANT NOTE FOR macOS USERS${NC}"
  echo "💡 Docker on macOS requires manual sharing of the /opt directory with Docker Desktop."
  echo "🔧 Please follow these steps:"
  echo ""
  echo "1. Open Docker Desktop → Settings → Resources → File Sharing"
  echo "2. Click the '+' button and add the path: /opt"
  echo "3. Click Apply & Restart to restart Docker"
  echo ""
  echo "👉 See official guide: https://docs.docker.com/desktop/settings/mac/#file-sharing"
  echo ""
fi
