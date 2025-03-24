check_required_envs() {
  for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
      echo -e "${RED}❌ Lỗi: Biến '$var' chưa được định nghĩa trong config.sh${NC}"
      exit 1
    fi
  done
}