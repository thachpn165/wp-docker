
php_choose_version() {
  local PHP_VERSION_FILE="$BASE_DIR/php_versions.txt"

  if [[ ! -f "$PHP_VERSION_FILE" ]]; then
    echo -e "${RED}❌ Không tìm thấy danh sách phiên bản PHP tại: $PHP_VERSION_FILE${NC}"
    return 1
  fi

  PHP_VERSIONS=()
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" ]] && PHP_VERSIONS+=("$line")
  done < "$PHP_VERSION_FILE"

  if [[ ${#PHP_VERSIONS[@]} -eq 0 ]]; then
    echo -e "${RED}❌ Danh sách phiên bản PHP rỗng. Vui lòng chạy lại lệnh cập nhật phiên bản PHP.${NC}"
    echo -e "${YELLOW}👉 Gợi ý: bash shared/scripts/setup-system.sh${NC}"
    return 1
  fi

  echo -e "${YELLOW}📦 Danh sách phiên bản PHP hỗ trợ (Bitnami):${NC}"
  for i in "${!PHP_VERSIONS[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${PHP_VERSIONS[$i]}"
  done

  echo -e "\n${YELLOW}⚠️ Ghi chú:${NC}"
  echo -e "${RED}- PHP 8.0 trở xuống có thể KHÔNG hoạt động trên hệ điều hành ARM như:${NC}"
  echo -e "  ${CYAN}- Apple Silicon (M1, M2,...), Raspberry Pi, máy chủ ARM64...${NC}"
  echo -e "  ${WHITE}→ Nếu gặp lỗi \"platform mismatch\", hãy thêm:${NC}"
  echo -e "     ${GREEN}platform: linux/amd64${NC} trong docker-compose.yml"
  echo -e "     ${WHITE}Sau đó sử dụng tính năng Restart website để khởi động lại"
  sleep 0.2
  echo ""
  read -p "🔹 Nhập số tương ứng với phiên bản PHP muốn chọn: " php_index

  if ! [[ "$php_index" =~ ^[0-9]+$ ]] || (( php_index < 0 || php_index >= ${#PHP_VERSIONS[@]} )); then
    echo -e "${RED}❌ Lựa chọn không hợp lệ.${NC}"
    return 1
  fi

  REPLY="${PHP_VERSIONS[$php_index]}"
}
