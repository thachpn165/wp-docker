#!/bin/bash

INSTALL_DIR="/opt/wp-docker"
ZIP_NAME="wp-docker.zip"
REPO_TAG=""
DOWNLOAD_URL=""
DEV_REPO_DIR="$HOME/wp-docker"
DEV_MODE=${DEV_MODE:-false}

# ========================
# 📌 Version Selection
# ========================
echo "❓ What version would you like to install?"
echo "1) Official"
echo "2) Nightly (Testing Only)"
echo "3) Dev Mode (Clone source code from GitHub)"
read -rp "Please select an option (1, 2 or 3, default is 1): " version_choice
version_choice=${version_choice:-1}

case "$version_choice" in
2)
  REPO_TAG="nightly"
  INSTALL_CHANNEL="nightly"
  DEV_MODE=false
  DOWNLOAD_URL="https://github.com/thachpn165/wp-docker/releases/download/$REPO_TAG/$ZIP_NAME"
  echo "🛠 Installing Nightly (Testing Only) version"
  ;;
3)
  INSTALL_CHANNEL="dev"
  DEV_MODE=true
  echo "🔧 Enabling Dev Mode: Clone from GitHub"
  ;;
*)
  REPO_TAG="latest"
  INSTALL_CHANNEL="official"
  DEV_MODE=false
  DOWNLOAD_URL="https://github.com/thachpn165/wp-docker/releases/download/$REPO_TAG/$ZIP_NAME"
  echo "🛠 Installing Official version"
  ;;
esac

# ========================
# 🧹 Clean previous installation
# ========================
if [[ "$DEV_MODE" == "true" ]]; then
  if [[ -L "$INSTALL_DIR" || -d "$INSTALL_DIR" ]]; then
    echo "⚠️ $INSTALL_DIR already exists (Dev Mode: likely a symlink)."
    read -rp "❓ Remove and re-create? [y/N]: " confirm
    [[ "$confirm" =~ ^[yY]$ ]] || {
      echo "Installation cancelled."
      exit 0
    }
    rm -rf "$INSTALL_DIR"
  fi
else
  if [[ -d "$INSTALL_DIR" ]]; then
    echo "⚠️ Directory $INSTALL_DIR already exists."
    read -rp "❓ Delete and overwrite? [y/N]: " confirm
    [[ "$confirm" =~ ^[yY]$ ]] || {
      echo "Installation cancelled."
      exit 0
    }
    rm -rf "$INSTALL_DIR"
  fi
fi

check_and_install_zip_unzip() {
  local cmds=("zip" "unzip")
  local missing=()

  # Kiểm tra từng lệnh
  for cmd in "${cmds[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
      echo "⚠️  Command '$cmd' is missing."
      missing+=("$cmd")
    else
      echo "✅ Command '$cmd' is already installed."
    fi
  done

  # Nếu không thiếu gì thì thoát
  if [[ ${#missing[@]} -eq 0 ]]; then
    return 0
  fi

  echo "📦 Installing missing package(s): ${missing[*]}"

  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v apt &>/dev/null; then
      sudo apt update -y && sudo apt install -y "${missing[@]}"
    elif command -v yum &>/dev/null; then
      sudo yum install -y "${missing[@]}"
    elif command -v dnf &>/dev/null; then
      sudo dnf install -y "${missing[@]}"
    else
      echo "❌ Unsupported Linux package manager. Please install: ${missing[*]}"
      return 1
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v brew &>/dev/null; then
      echo "📦 Homebrew not found. Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install "${missing[@]}"
  else
    echo "❌ Unsupported OS: $OSTYPE"
    return 1
  fi

  echo "✅ Installation of zip/unzip completed."
}
check_and_install_zip_unzip

# ========================
# 📥 Download or Clone Source
# ========================
if [[ "$DEV_MODE" == "true" ]]; then
  echo "🚧 DEV_MODE enabled. Cloning to: $DEV_REPO_DIR"
  git clone https://github.com/thachpn165/wp-docker "$DEV_REPO_DIR"
  ln -sfn "$DEV_REPO_DIR/src" "$INSTALL_DIR"
else
  echo "📦 Downloading source code from GitHub..."
  curl -L "$DOWNLOAD_URL" -o "$ZIP_NAME" || {
    echo "❌ Download failed"
    exit 1
  }
  echo "📁 Extracting to $INSTALL_DIR..."
  mkdir -p "$INSTALL_DIR"
  unzip -q "$ZIP_NAME" -d "$INSTALL_DIR"
  rm -f "$ZIP_NAME"
fi

# ========================
# ⚙️ Run setup-system.sh
# ========================
if [[ -f "$INSTALL_DIR/shared/config/load_config.sh" ]]; then
  source "$INSTALL_DIR/shared/config/load_config.sh"
  load_config_file
fi

if [[ -f "$INSTALL_DIR/shared/scripts/setup/setup-system.sh" ]]; then
  chmod +x "$INSTALL_DIR/shared/scripts/setup/setup-system.sh"
  bash "$INSTALL_DIR/shared/scripts/setup/setup-system.sh"
fi

check_required_commands
# ========================
# 🛠 Ensure .config.json exists
# ========================
if [[ -z "$BASE_DIR" ]]; then
  echo "❌ BASE_DIR not defined. Please load config.sh first." >&2
  exit 1
fi

if [[ ! -f "$JSON_CONFIG_FILE" ]]; then
  echo "{}" >"$JSON_CONFIG_FILE"
  echo "Created initial config file: $JSON_CONFIG_FILE"
else
  echo "Config file already exists: $JSON_CONFIG_FILE"
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
# 💾 Save install channel to .config.json
# ========================

if [[ -n "$INSTALL_CHANNEL" ]]; then
  core_set_channel "$INSTALL_CHANNEL"
  print_msg success "$(printf "$SUCCESS_CORE_CHANNEL_SET" "$INSTALL_CHANNEL" "$JSON_CONFIG_FILE")"
else
  print_msg warning "⚠️ INSTALL_CHANNEL not set. Skipping channel save."
fi

print_msg success "✅ Installation successful at: $INSTALL_DIR"

# =========================
# Set latest version to .config.json
# =========================
safe_source "$INSTALL_DIR/shared/scripts/functions/core/core_version_management.sh"
latest_version=$(core_version_get_latest)
core_set_installed_version "$latest_version"
# ========================
# 🍏 macOS File Sharing Warning
# ========================
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo ""
  echo "⚠️  IMPORTANT NOTE FOR macOS USERS"
  echo "💡 Docker on macOS requires manual sharing of the /opt directory."
  echo "🔧 Steps:"
  echo " 1. Open Docker Desktop → Settings → Resources → File Sharing"
  echo " 2. Add: /opt"
  echo " 3. Click Apply & Restart"
  echo "👉 Guide: https://docs.docker.com/desktop/settings/mac/#file-sharing"
  echo ""
fi
