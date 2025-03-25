php_get_version() {
  local output_file="$PROJECT_ROOT/php_versions.txt"
  echo -e "${CYAN}🌐 Đang lấy danh sách phiên bản PHP từ Bitnami...${NC}"

  versions=$(curl -s --max-time 10 "https://hub.docker.com/v2/repositories/bitnami/php-fpm/tags?page_size=100" \
    | grep -oE '\"name\":\"[0-9]+\.[0-9]+\"' \
    | cut -d':' -f2 | tr -d '"' \
    | grep -E '^7\.[4-9]$|^8\.[0-9]+$|^9\.[0-9]+' \
    | sort -Vr | uniq)

  if [[ -z "$versions" ]]; then
    echo -e "${RED}⚠️ Không thể lấy phiên bản PHP từ Docker Hub. Dùng mặc định.${NC}"
    versions="8.3 8.2 8.1 7.4"
  fi

  : > "$output_file"
  for version in $versions; do
    echo "$version" >> "$output_file"
  done

  echo -e "${GREEN}✅ Đã lưu danh sách tag PHP chính xác vào: $output_file${NC}"
}
