# =====================================
# 📝 website_create_env – Create .env file for website
# =====================================

website_create_env() {
  local output_dir="$1"
  local site_name="$2"
  local domain="$3"
  local php_version="$4"

  # Check input parameters
  if [[ "$TEST_MODE" != true && $# -ne 4 ]]; then
    echo -e "${RED}❌ Missing parameters when calling website_create_env().${NC}"
    echo -e "${YELLOW}Usage: website_create_env <output_dir> <site_name> <domain> <php_version>${NC}"
    return 1
  fi


  local env_file="$output_dir/.env"

  MYSQL_ROOT_PASSWORD=$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9' | head -c 16)
  MYSQL_PASSWORD=$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9' | head -c 16)

  mkdir -p "$output_dir"

  cat > "$env_file" <<EOF
SITE_NAME=$site_name
DOMAIN=$domain
PHP_VERSION=$php_version
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=$MYSQL_PASSWORD
EOF

  echo -e "${GREEN}✅ Created .env file at $env_file${NC}"
}
