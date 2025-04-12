# ========================================================================
# CLI Parameters Functions
# Used to parse command line arguments and options
# ========================================================================

# Parse required params
_parse_params() {
  local param_name="$1"
  local param_value=""
  
  # Kiểm tra nếu tham số không được truyền vào
  if [[ -z "$param_name" ]]; then
    print_msg error "$ERROR_MISSING_PARAM: $param_name"
    return 1
  fi

  # Parse tham số (kiểm tra theo tham số)
  for arg in "$@"; do
    case $arg in
    "${param_name}"=*) param_value="${arg#*=}" ;;
    esac
  done

  # Trả về giá trị của tham số nếu hợp lệ
  echo "$param_value"
}

# Parse optinal params
_parse_optional_params() {
  local param_name="$1"
  local param_value=""

  # Kiểm tra nếu tham số không được truyền vào
  if [[ -z "$param_name" ]]; then
    print_msg error "$ERROR_MISSING_PARAM: $param_name"
    exit 1
  fi

  # Parse tham số (kiểm tra theo tham số)
  for arg in "$@"; do
    case $arg in
    "${param_name}"=*) param_value="${arg#*=}" ;;
    esac
  done

  # Trả về giá trị của tham số
  echo "$param_value"
}