#!/bin/bash

INSTALL_DIR="/opt/wp-docker"
REPO_URL="https://github.com/thachpn165/wp-docker"
ZIP_NAME="wp-docker.zip"
DEV_MODE=false
CORE_ENV="$INSTALL_DIR/.env"

source "$INSTALL_DIR/shared/scripts/functions/core/env_utils.sh"
# ========================
# ⚙️ Command Line Parameter Processing
# ========================
# Ask the user to choose version: Official or Nightly (Testing Only)
echo "❓ What version would you like to install?"
echo "1) Official"
echo "2) Nightly (Testing Only)"

read -rp "Please select an option (1 or 2, default is 1): " version_choice

# Set default option to Official (1) if no input is provided
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
  echo "${WARNING} Directory $INSTALL_DIR already exists."
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
# Set permissions for current user
# ========================
echo "🔐 Setting permissions for user: $USER"
chown -R "$USER" "$INSTALL_DIR"

# ========================
# 🔗 Create global alias if not in dev mode
# ========================
# Check if alias is already set in ~/.bashrc or ~/.zshrc
check_and_add_alias() {
  local shell_config
  local alias_line
  # Get the absolute path of the bin directory
  local cli_dir_abs=$(realpath "$INSTALL_DIR/shared/bin")
  alias_line="alias wpdocker=\"bash $cli_dir_abs/wpdocker\""

  # Check if using Zsh or Bash
  if [[ "$SHELL" == *"zsh"* ]]; then
    shell_config="$HOME/.zshrc"
  else
    shell_config="$HOME/.bashrc"
  fi

  # Check if the alias is already present
  if ! grep -q "$alias_line" "$shell_config"; then
    echo "Adding alias for wpdocker to $shell_config..."
    echo "$alias_line" >> "$shell_config"
  else
    echo "${WARNING} Alias 'wpdocker' already exists in $shell_config"
  fi
  
  # Reload the shell configuration file to apply changes
  if [[ "$SHELL" == *"zsh"* ]]; then
      # If the current shell is zsh, source .zshrc
      echo "Sourcing .zshrc to reload Zsh configuration..."
      source "$HOME/.zshrc"
  elif [[ "$SHELL" == *"bash"* ]]; then
      # If the current shell is bash, source .bashrc
      echo "Sourcing .bashrc to reload Bash configuration..."
      source "$HOME/.bashrc"
  else
      echo "Unsupported shell: $SHELL. Please reload your shell configuration manually."
  fi

}
check_and_add_alias

echo "Installation successful at: $INSTALL_DIR"

# Save install channel to .env
env_set_value "CORE_CHANNEL" "$INSTALL_CHANNEL"

# ========================
# 📢 Special warning for macOS (Docker Desktop)
# ========================
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo ""
  echo "${WARNING}  ${YELLOW}IMPORTANT NOTE FOR macOS USERS${NC}"
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