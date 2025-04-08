#!/bin/bash

INSTALL_DIR="/opt/wp-docker"
REPO_URL="https://github.com/thachpn165/wp-docker"
ZIP_NAME="wp-docker.zip"
DEV_MODE=false
CORE_ENV="$INSTALL_DIR/.env"

# ========================
# ⚙️ Command Line Parameter Processing
# ========================
echo "❓ What version would you like to install?"
echo "1) Official"
echo "2) Nightly (Testing Only)"
read -rp "Please select an option (1 or 2, default is 1): " version_choice
version_choice=${version_choice:-1}

if [[ "$version_choice" == "2" ]]; then
  ZIP_NAME="wp-docker-dev.zip"
  echo "🛠 Installing Nightly (Testing Only) version"
  DOWNLOAD_URL="$REPO_URL/releases/download/nightly/$ZIP_NAME"
  INSTALL_CHANNEL="nightly"
else
  echo "🛠 Installing Official version"
  DOWNLOAD_URL="$REPO_URL/releases/latest/download/$ZIP_NAME"
  INSTALL_CHANNEL="official"
fi

# ========================
# 🧹 Check if directory exists
# ========================
if [[ -d "$INSTALL_DIR" ]]; then
  echo "⚠️ Directory $INSTALL_DIR already exists."
  read -rp "❓ Do you want to delete and overwrite it? [y/N]: " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Installation cancelled."
    exit 0
  fi
  rm -rf "$INSTALL_DIR"
fi

# ========================
# 📥 Download and extract release
# ========================
echo "📦 Downloading source code from GitHub Release..."
curl -L "$DOWNLOAD_URL" -o "$ZIP_NAME" || { echo "Command failed at line 35"; exit 1; }
echo "📁 Extracting to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
unzip -q "$ZIP_NAME" -d "$INSTALL_DIR"
rm "$ZIP_NAME" || { echo "Command failed at line 40"; exit 1; }

# ========================
# ✅ Load config & setup system
# ========================
if [[ -f "$INSTALL_DIR/shared/config/load_config.sh" ]]; then
  source "$INSTALL_DIR/shared/config/load_config.sh"
  load_config_file
fi

if [[ -f "$INSTALL_DIR/shared/scripts/setup/setup-system.sh" ]]; then
  bash "$INSTALL_DIR/shared/scripts/setup/setup-system.sh"
fi

# ========================
# Set permissions
# ========================
echo "🔐 Setting permissions for user: $USER"
chown -R "$USER" "$INSTALL_DIR"

# ========================
# 🔗 Create global alias
# ========================
check_and_add_alias() {
  local shell_config
  local alias_line
  local cli_dir_abs=$(realpath "$INSTALL_DIR/shared/bin")
  alias_line="alias wpdocker=\"bash $cli_dir_abs/wpdocker\""

  if [[ "$SHELL" == *"zsh"* ]]; then
    shell_config="$HOME/.zshrc"
  else
    shell_config="$HOME/.bashrc"
  fi

  if ! grep -q "$alias_line" "$shell_config"; then
    echo "Adding alias for wpdocker to $shell_config..."
    echo "$alias_line" >> "$shell_config"
  else
    echo "⚠️ Alias 'wpdocker' already exists in $shell_config"
  fi

  if [[ "$SHELL" == *"zsh"* ]]; then
    source "$HOME/.zshrc"
  elif [[ "$SHELL" == *"bash"* ]]; then
    source "$HOME/.bashrc"
  else
    echo "Unsupported shell: $SHELL. Please reload your shell configuration manually."
  fi
}
check_and_add_alias

# Save install channel to .env (manual fallback if env_set_value not ready)
if grep -q "^CORE_CHANNEL=" "$CORE_ENV" 2>/dev/null; then
  sed -i.bak "s/^CORE_CHANNEL=.*/CORE_CHANNEL=$INSTALL_CHANNEL/" "$CORE_ENV"
else
  echo "CORE_CHANNEL=$INSTALL_CHANNEL" >> "$CORE_ENV"
fi

echo "✅ Installation successful at: $INSTALL_DIR"

# ========================
# 📢 Special warning for macOS
# ========================
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo ""
  echo "⚠️  IMPORTANT NOTE FOR macOS USERS"
  echo "💡 Docker on macOS requires manual sharing of the /opt directory with Docker Desktop."
  echo "🔧 Please follow these steps:"
  echo "1. Open Docker Desktop → Settings → Resources → File Sharing"
  echo "2. Add the path: /opt"
  echo "3. Click Apply & Restart"
  echo "👉 Guide: https://docs.docker.com/desktop/settings/mac/#file-sharing"
  echo ""
fi