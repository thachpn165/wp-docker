# =====================================
# 📝 website_create_env – Create .env file for website
# =====================================

website_create_env() {
  local output_dir="$1"
  local domain="$2"
  local php_version="$3"

  # Check input parameters
  if [[ "$TEST_MODE" != true && $# -ne 3 ]]; then
    echo -e "${RED}${CROSSMARK} Missing parameters when calling website_create_env().${NC}"
    echo -e "${YELLOW}Usage: website_create_env <output_dir> <domain> <php_version>${NC}"
    return 1
  fi

  local env_file="$output_dir/.env"

  MYSQL_ROOT_PASSWORD=$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9' | head -c 16)
  MYSQL_PASSWORD=$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9' | head -c 16)

  mkdir -p "$output_dir"

  cat > "$env_file" <<EOF
DOMAIN=$domain
PHP_VERSION=$php_version
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=$MYSQL_PASSWORD
CONTAINER_PHP=${domain}${PHP_CONTAINER_SUFFIX}
CONTAINER_DB=${domain}${DB_CONTAINER_SUFFIX}
EOF

  echo -e "${GREEN}${CHECKMARK} Created .env file at $env_file${NC}"
}