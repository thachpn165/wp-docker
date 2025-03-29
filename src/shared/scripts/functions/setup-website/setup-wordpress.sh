#!/bin/bash

# =====================================
# 📣 Script to install WordPress for the created website
# =====================================

# === Auto-detect PROJECT_DIR ===
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

CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi
source "$CONFIG_FILE"


# ✉️ Get site parameter
site_name="${1:-}"
if [[ -z "$site_name" ]]; then
  echo -e "${RED}❌ Missing site name parameter.${NC}"
  exit 1
fi

# 🗂️ Determine directory containing .env
SITE_DIR="$SITES_DIR/$site_name"
ENV_FILE="$SITE_DIR/.env"

# If not found in sites/, try to find in tmp/
if [[ ! -f "$ENV_FILE" ]]; then
  tmp_env_path=$(find "$TMP_DIR" -maxdepth 1 -type d -name "${site_name}_*" | head -n 1)
  if [[ -n "$tmp_env_path" && -f "$tmp_env_path/.env" ]]; then
    ENV_FILE="$tmp_env_path/.env"
    SITE_DIR="$tmp_env_path"
  else
    echo -e "${RED}❌ .env file not found for site '$site_name'${NC}"
    exit 1
  fi
fi
ENV_FILE_DIR=$(dirname "$ENV_FILE")

# ↺ Load variables from .env
DOMAIN=$(fetch_env_variable "$ENV_FILE" "DOMAIN")
DB_NAME=$(fetch_env_variable "$ENV_FILE" "MYSQL_DATABASE")
DB_USER=$(fetch_env_variable "$ENV_FILE" "MYSQL_USER")
DB_PASS=$(fetch_env_variable "$ENV_FILE" "MYSQL_PASSWORD")
PHP_VERSION=$(fetch_env_variable "$ENV_FILE" "PHP_VERSION")

# ⚖️ Containers
PHP_CONTAINER="${site_name}-php"
DB_CONTAINER="${site_name}-mariadb"
SITE_URL="https://$DOMAIN"

# 🔐 Input admin information
[[ "$TEST_MODE" != true ]] && read -p "👤 Would you like the system to automatically generate a strong admin account? [Y/n]: " auto_gen
auto_gen="${auto_gen:-Y}"
auto_gen="$(echo "$auto_gen" | tr '[:upper:]' '[:lower:]')"

if [[ "$auto_gen" == "n" ]]; then
  [[ "$TEST_MODE" != true ]] && read -p "👤 Enter admin username: " ADMIN_USER
  while [[ -z "$ADMIN_USER" ]]; do
    echo "⚠️ Cannot be empty."
    [[ "$TEST_MODE" != true ]] && read -p "👤 Enter admin username: " ADMIN_USER
  done
  read -s -p "🔐 Enter admin password: " ADMIN_PASSWORD; echo
  read -s -p "🔐 Confirm password: " CONFIRM_PASSWORD; echo
  while [[ "$ADMIN_PASSWORD" != "$CONFIRM_PASSWORD" || -z "$ADMIN_PASSWORD" ]]; do
    echo "⚠️ Passwords do not match or are empty. Please try again."
    read -s -p "🔐 Enter admin password: " ADMIN_PASSWORD; echo
    read -s -p "🔐 Confirm password: " CONFIRM_PASSWORD; echo
  done
  [[ "$TEST_MODE" != true ]] && read -p "📧 Enter admin email (ENTER to use admin@$site_name.local): " ADMIN_EMAIL
  ADMIN_EMAIL="${ADMIN_EMAIL:-admin@$site_name.local}"
else
  ADMIN_USER="admin-$(openssl rand -base64 6 | tr -dc 'a-zA-Z0-9' | head -c 8)"
  ADMIN_PASSWORD="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c 16)"
  ADMIN_EMAIL="admin@$site_name.local"
fi

# ✨ Start notification
echo -e "${BLUE}▹ Starting WordPress installation for '$site_name'...${NC}"

# ⏳ Check if PHP container is ready
echo -e "${YELLOW}⏳ Waiting for PHP container '$PHP_CONTAINER' to start...${NC}"
timeout=30
while ! is_container_running "$PHP_CONTAINER"; do
  sleep 1
  ((timeout--))
  if (( timeout <= 0 )); then
    echo -e "${RED}❌ PHP container '$PHP_CONTAINER' not ready after 30s.${NC}"
    exit 1
  fi
  echo -ne "⏳ Waiting for PHP container... ($((30-timeout))/30)\r"
done

# 📦 Download WordPress source if not exists
if [[ ! -f "$SITE_DIR/wordpress/index.php" ]]; then
  echo -e "${YELLOW}📦 Downloading WordPress...${NC}"

  # Check target directory in container before downloading
  docker exec -i "$PHP_CONTAINER" sh -c "mkdir -p /var/www/html && chown -R nobody:nogroup /var/www/html"
  
  # Download and extract WordPress to correct directory
  docker exec -i "$PHP_CONTAINER" sh -c "curl -o /var/www/html/wordpress.tar.gz -L https://wordpress.org/latest.tar.gz && \
    tar -xzf /var/www/html/wordpress.tar.gz --strip-components=1 -C /var/www/html && rm /var/www/html/wordpress.tar.gz"

  echo -e "${GREEN}✅ WordPress source code downloaded.${NC}"
else
  echo -e "${GREEN}✅ WordPress source code already exists.${NC}"
fi

# ⚙️ Install wp-config
wp_set_wpconfig "$PHP_CONTAINER" "$DB_NAME" "$DB_USER" "$DB_PASS" "$DB_CONTAINER"

# 🚀 Install WordPress
wp_install "$PHP_CONTAINER" "$SITE_URL" "$site_name" "$ADMIN_USER" "$ADMIN_PASSWORD" "$ADMIN_EMAIL"

# 🛠️ Permissions & optimization
if is_container_running "$PHP_CONTAINER"; then
  docker exec -u root "$PHP_CONTAINER" chown -R nobody:nogroup "/var/www/" || {
    echo -e "${RED}❌ Permission setting failed.${NC}"
    exit 1
  }
else
  echo -e "${RED}❌ Skipping chown as container is not ready.${NC}"
fi

wp_set_permalinks "$PHP_CONTAINER" "$SITE_URL"
# wp_plugin_install_performance_lab "$PHP_CONTAINER" # Enable if needed

# 📝 Save information
cat > "$ENV_FILE_DIR/.wp-info" <<EOF
🌍 Website URL:   $SITE_URL
🔑 Admin URL:     $SITE_URL/wp-admin
👤 Admin User:    $ADMIN_USER
🔒 Admin Pass:    $ADMIN_PASSWORD
📧 Admin Email:   $ADMIN_EMAIL
EOF
