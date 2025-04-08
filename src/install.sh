#!/bin/bash

INSTALL_DIR="/opt/wp-docker"
ZIP_NAME="wp-docker.zip"
REPO_TAG=""
DOWNLOAD_URL=""
DEV_REPO_DIR="$HOME/wp-docker"
DEV_MODE=${DEV_MODE:-false}

# ========================
# ⚙️ Version Selection Prompt
# ========================
echo "❓ What version would you like to install?"
echo "1) Official"
echo "2) Nightly (Testing Only)"
echo "3) Dev Mode (Clone source code from GitHub)"
read -rp "Please select an option (1, 2 or 3, default is 1): " version_choice
version_choice=${version_choice:-1}

if [[ "$version_choice" == "2" ]]; then
  REPO_TAG="nightly"
  DOWNLOAD_URL="https://github.com/thachpn165/wp-docker/releases/download/$REPO_TAG/$ZIP_NAME"
  echo "🛠 Installing Nightly (Testing Only) version"
  INSTALL_CHANNEL="nightly"
  DEV_MODE=false
elif [[ "$version_choice" == "3" ]]; then
  echo "🔧 Enabling Dev Mode: Clone from GitHub"
  INSTALL_CHANNEL="dev"
  DEV_MODE=true
else
  REPO_TAG="latest"
  DOWNLOAD_URL="https://github.com/thachpn165/wp-docker/releases/download/$REPO_TAG/$ZIP_NAME"
  echo "🛠 Installing Official version"
  INSTALL_CHANNEL="official"
  DEV_MODE=false
fi

# ========================
# 🧹 Clean if existed (with Dev Mode awareness)
# ========================
if [[ "$DEV_MODE" == "true" ]]; then
  # Remove symlink or dir in dev mode
  if [[ -L "$INSTALL_DIR" || -d "$INSTALL_DIR" ]]; then
    echo "⚠️ $INSTALL_DIR already exists (may be a symlink in Dev Mode)."
    read -rp "❓ Do you want to remove this symlink and re-create? [y/N]: " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
      echo "Installation cancelled."
      exit 0
    fi
    rm -rf "$INSTALL_DIR"
  fi
else
  # Remove full directory if not in dev mode
  if [[ -d "$INSTALL_DIR" ]]; then
    echo "⚠️ Directory $INSTALL_DIR already exists."
    read -rp "❓ Do you want to delete and overwrite it? [y/N]: " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
      echo "Installation cancelled."
      exit 0
    fi
    rm -rf "$INSTALL_DIR"
  fi
fi

# ========================
# 📥 Clone or Download Source
# ========================
if [[ "$DEV_MODE" == "true" ]]; then
  echo "🚧 DEV_MODE is enabled. Cloning source to: $DEV_REPO_DIR"
  REPO_URL="https://github.com/thachpn165/wp-docker"
  git clone "$REPO_URL" "$DEV_REPO_DIR"
  ln -sfn "$DEV_REPO_DIR/src" "$INSTALL_DIR"
else
  echo "📦 Downloading source code from GitHub Release..."
  curl -L "$DOWNLOAD_URL" -o "$ZIP_NAME" || { echo "❌ Download failed"; exit 1; }

  echo "📁 Extracting to $INSTALL_DIR..."
  mkdir -p "$INSTALL_DIR"
  unzip -q "$ZIP_NAME" -d "$INSTALL_DIR"
  rm -f "$ZIP_NAME"
fi

# ========================
# ✅ Load config & run setup-system.sh
# ========================
if [[ -f "$INSTALL_DIR/shared/config/load_config.sh" ]]; then
  source "$INSTALL_DIR/shared/config/load_config.sh"
  load_config_file
fi

if [[ -f "$INSTALL_DIR/shared/scripts/setup/setup-system.sh" ]]; then
  chmod +x "$INSTALL_DIR/shared/scripts/setup/setup-system.sh"
  bash "$INSTALL_DIR/shared/scripts/setup/setup-system.sh"
fi


# =============================================
# 🔧 Initialize .config.json if not exists
# =============================================
if [[ -z "$BASE_DIR" ]]; then
  echo "❌ BASE_DIR not defined. Please load config.sh first." >&2
  exit 1
fi


if [[ ! -f "$CONFIG_JSON_FILE" ]]; then
  echo "{}" > "$CONFIG_JSON_FILE"
  echo "✅ Created initial config file: $CONFIG_JSON_FILE"
else
  echo "ℹ️ Config file already exists: $CONFIG_JSON_FILE"
fi

# ========================
# 🔐 Set Permissions
# ========================
echo "🔐 Setting permissions for user: $USER"
chown -R "$USER" "$INSTALL_DIR"

# ========================
# 🔗 Setup global alias
# ========================
check_and_add_alias

# ========================
# 💾 Set core.channel in .config.json
# ========================
if [[ -n "$INSTALL_CHANNEL" ]]; then
  core_set_channel "$INSTALL_CHANNEL"
  print_msg success "$(printf "$SUCCESS_CORE_CHANNEL_SET" "$INSTALL_CHANNEL" "$JSON_CONFIG_FILE")"
else
  print_msg warning "⚠️ Không có giá trị INSTALL_CHANNEL để lưu channel."
fi

print_msg success "✅ Installation successful at: $INSTALL_DIR"

# ========================
# 📢 macOS warning
# ========================
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo ""
  echo "⚠️  IMPORTANT NOTE FOR macOS USERS"
  echo "💡 Docker on macOS requires manual sharing of the /opt directory with Docker Desktop."
  echo "🔧 Steps:"
  echo " 1. Open Docker Desktop → Settings → Resources → File Sharing"
  echo " 2. Add: /opt"
  echo " 3. Click Apply & Restart"
  echo "👉 Guide: https://docs.docker.com/desktop/settings/mac/#file-sharing"
  echo ""
fi