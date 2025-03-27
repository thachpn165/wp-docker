# Định nghĩa các hàm tiện ích không thuộc một chuyên mục cụ thể nào

# =========================================
# 🧪 Liên quan đến môi trường hệ thống
# =========================================
# 📝 **Kiểm tra các biến môi trường bắt buộc**
check_required_envs() {
  for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
      echo -e "${RED}❌ Lỗi: Biến '$var' chưa được định nghĩa trong config.sh${NC}"
      exit 1
    fi
  done
}

# =========================================
# 🧪 Hàm hỗ trợ TEST_MODE
# =========================================

# ✅ Kiểm tra có đang ở chế độ test không
is_test_mode() {
  [[ "$TEST_MODE" == true ]]
}

# ✅ Thực thi lệnh nếu không phải test, nếu test thì trả về giá trị fallback
# Cách dùng:
#   domain=$(run_if_not_test "example.com" get_input_domain)
run_if_not_test() {
  local fallback="$1"
  shift
  if is_test_mode; then
    echo "$fallback"
  else
    "$@"
  fi
}

# ✅ Chạy 1 lệnh (hoặc hàm) chỉ khi không phải TEST_MODE
# Cách dùng:
#   run_unless_test docker compose up -d
run_unless_test() {
  if ! is_test_mode; then
    "$@"
  else
    echo "🧪 Bỏ qua trong TEST_MODE: $*" >&2
  fi
}