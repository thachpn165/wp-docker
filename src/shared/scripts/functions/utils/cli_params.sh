# ========================================================================
# CLI Parameters Functions
# Used to parse command line arguments and options
# ========================================================================

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

  # Kiểm tra lại nếu param_value không được xác định
  if [[ -z "$param_value" ]]; then
    print_msg error "$ERROR_MISSING_PARAM: $param_name"
    print_msg info "$INFO_PARAM_EXAMPLE:\n  ${param_name}=value"
    return 1
  fi

  # Trả về giá trị của tham số
  echo "$param_value"
}