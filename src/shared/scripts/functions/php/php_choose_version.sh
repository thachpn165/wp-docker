php_choose_version() {
  local PHP_VERSION_FILE="$BASE_DIR/php_versions.txt"

  if [[ ! -f "$PHP_VERSION_FILE" ]]; then
    echo -e "${RED}❌ PHP version list not found at: $PHP_VERSION_FILE${NC}"
    return 1
  fi

  PHP_VERSIONS=()
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" ]] && PHP_VERSIONS+=("$line")
  done < "$PHP_VERSION_FILE"

  if [[ ${#PHP_VERSIONS[@]} -eq 0 ]]; then
    echo -e "${RED}❌ PHP version list is empty. Please run the PHP version update command again.${NC}"
    echo -e "${YELLOW}👉 Tip: bash shared/scripts/setup-system.sh${NC}"
    return 1
  fi

  echo -e "${YELLOW}📦 Supported PHP versions (Bitnami):${NC}"
  for i in "${!PHP_VERSIONS[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${PHP_VERSIONS[$i]}"
  done

  echo -e "\n${YELLOW}⚠️ Note:${NC}"
  echo -e "${RED}- PHP 8.0 and below may NOT work on ARM operating systems such as:${NC}"
  echo -e "  ${CYAN}- Apple Silicon (M1, M2,...), Raspberry Pi, ARM64 servers...${NC}"
  echo -e "  ${WHITE}→ If you encounter \"platform mismatch\" error, add:${NC}"
  echo -e "     ${GREEN}platform: linux/amd64${NC} in docker-compose.yml"
  echo -e "     ${WHITE}Then use the Restart website feature to restart"
  sleep 0.2
  echo ""
  read -p "🔹 Enter the number corresponding to the PHP version you want to select: " php_index

  if ! [[ "$php_index" =~ ^[0-9]+$ ]] || (( php_index < 0 || php_index >= ${#PHP_VERSIONS[@]} )); then
    echo -e "${RED}❌ Invalid selection.${NC}"
    return 1
  fi

  REPLY="${PHP_VERSIONS[$php_index]}"
}
