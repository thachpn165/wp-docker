#!/bin/bash

INSTALL_DIR="/opt/wp-docker"
REPO_URL="https://github.com/thachpn165/wp-docker"
ZIP_NAME="wp-docker.zip"
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
  ZIP_NAME="wp-docker-dev.zip"
  echo "🛠 Installing Nightly (Testing Only) version"
  DOWNLOAD_URL="$REPO_URL/releases/download/nightly/$ZIP_NAME"
  INSTALL_CHANNEL="nightly"
  DEV_MODE=false
elif [[ "$version_choice" == "3" ]]; then
  echo "🔧 Enabling Dev Mode: Clone from GitHub"
  INSTALL_CHANNEL="dev"
  DEV_MODE=true
else
  echo "🛠 Installing Official version"
  DOWNLOAD_URL="$REPO_URL/releases/latest/download/$ZIP_NAME"
  INSTALL_CHANNEL="official"
  DEV_MODE=false
fi

# ========================
# 🧹 Clean if existed (with Dev Mode awareness)
# ========================
if [[ "$DEV_MODE" == "true" ]]; then
  # If in Dev Mode → remove symlink only
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
  # If not in Dev Mode → remove the entire directory
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
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
SEARCH_PATH="$SCRIPT_PATH"
while [[ "$SEARCH_PATH" != "/" ]]; do
  if [[ -f "$SEARCH_PATH/shared/config/load_config.sh" ]]; then
    source "$SEARCH_PATH/shared/config/load_config.sh"
    source "$FUNCTIONS_DIR/system/system_utils.sh"
    load_config_file
    break
  fi
  SEARCH_PATH="$(dirname "$SEARCH_PATH")"
done

if [[ -f "$INSTALL_DIR/shared/scripts/setup/setup-system.sh" ]]; then
  chmod +x "$INSTALL_DIR/shared/scripts/setup/setup-system.sh"
  bash "$INSTALL_DIR/shared/scripts/setup/setup-system.sh"
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
# 💾 Set CORE_CHANNEL in .env
# ========================
CORE_ENV="$INSTALL_DIR/.env"
if [[ -f "$CORE_ENV" ]]; then
  if grep -q "^CORE_CHANNEL=" "$CORE_ENV"; then
    sed -i.bak "s/^CORE_CHANNEL=.*/CORE_CHANNEL=$INSTALL_CHANNEL/" "$CORE_ENV"
  else
    echo "CORE_CHANNEL=$INSTALL_CHANNEL" >> "$CORE_ENV"
  fi
else
  echo "CORE_CHANNEL=$INSTALL_CHANNEL" > "$CORE_ENV"
fi

echo "✅ Installation successful at: $INSTALL_DIR"

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