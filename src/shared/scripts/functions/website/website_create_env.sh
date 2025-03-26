# =====================================
# 📝 website_create_env – Tạo file .env cho website
# =====================================

website_create_env() {
  local site_name="$1"
  local domain="$2"
  local php_version="$3"
  local output_dir="$4"

  if [[ -z "$site_name" || -z "$domain" || -z "$php_version" || -z "$output_dir" ]]; then
    echo -e "${RED}❌ Thiếu tham số khi gọi website_create_env().${NC}"
    echo -e "${YELLOW}Usage: website_create_env <site_name> <domain> <php_version> <output_dir>${NC}"
    return 1
  fi

  # Tạo mật khẩu ngẫu nhiên an toàn
  local mysql_root_pass
  local mysql_pass
  mysql_root_pass=$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9' | head -c 16)
  mysql_pass=$(openssl rand -base64 16 | tr -dc 'A-Za-z0-9' | head -c 16)

  mkdir -p "$output_dir"
  cat > "$output_dir/.env" <<EOF
SITE_NAME=$site_name
DOMAIN=$domain
PHP_VERSION=$php_version
MYSQL_ROOT_PASSWORD=$mysql_root_pass
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=$mysql_pass
EOF

  if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ Đã tạo file .env tại $output_dir/.env${NC}"
    return 0
  else
    echo -e "${RED}❌ Không thể ghi file .env tại $output_dir${NC}"
    return 1
  fi
}
