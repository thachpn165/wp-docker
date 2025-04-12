#!/bin/bash

# Debug function to enable detailed tracing
function debug_process() {
    export PS4='\e[36m+(${BASH_SOURCE}:${LINENO}):\e[0m ${FUNCNAME[0]:+\e[35m${FUNCNAME[0]}():\e[0m }'
    set -x
}

# === Helper: Load config.sh
load_config_file() {
  if [[ -z "$PROJECT_DIR" ]]; then
    SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
    
    # Iterate upwards from the current script directory to find 'config.sh'
    while [[ "$SCRIPT_PATH" != "/" ]]; do
      if [[ -f "$SCRIPT_PATH/shared/config/config.sh" ]]; then
        PROJECT_DIR="$SCRIPT_PATH"
        break
      fi
      SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
    done

    # Handle error if config file is not found
    if [[ -z "$PROJECT_DIR" ]]; then
      echo "${CROSSMARK} Unable to determine PROJECT_DIR. Please check the script's directory structure." >&2
      exit 1
    fi
  fi

  # Load the config file if PROJECT_DIR is set
  CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "${CROSSMARK} Config file not found at: $CONFIG_FILE" >&2
    exit 1
  fi

  # Source the config file
  safe_source "$CONFIG_FILE"
}

# Hàm safe_source thay thế source thông thường
# Kiểm tra xem file đã được source chưa và hiển thị debug info
safe_source() {
  local target_file="$1"
  local caller_file="${BASH_SOURCE[1]}"
  
  # Tạo tên biến dựa trên đường dẫn file (chuẩn hóa)
  local var_name
  var_name="WPDK_LOADED_$(realpath "$target_file" 2>/dev/null | tr './-' '_')"
  
  # Màu sắc
  local green='\033[0;32m'
  local yellow='\033[0;33m'
  local red='\033[0;31m'
  local reset='\033[0m'
  
  # Kiểm tra xem file đã được source chưa
  if [[ "$(eval echo \${$var_name:-false})" == "true" ]]; then
    # File đã được source, hiển thị thông báo (nếu debug mode bật)
    if [[ "${DEBUG_MODE:-false}" == "true" ]]; then
      echo -e "${green}[SAFE_SOURCE]${reset} File ${yellow}${target_file}${reset} đã được source trước đó, bỏ qua."
    fi
    return 0
  fi
  
  # Đánh dấu file đã được source
  eval "$var_name=true"
  
  # Hiển thị thông tin debug nếu DEBUG_MODE=true
  if [[ "${DEBUG_MODE:-false}" == "true" ]]; then
    echo -e "${green}[SOURCE]${reset} Từ file ${yellow}${caller_file:-unknown}${reset} đang source file ${yellow}${target_file}${reset}"
  fi
  
  # Kiểm tra file tồn tại
  if [[ ! -f "$target_file" ]]; then
    echo -e "${red}[SOURCE ERROR]${reset} File ${yellow}${target_file}${reset} không tồn tại!"
    return 1
  fi
  
  # Source file
  builtin source "$target_file"
  
  # Hiển thị trạng thái kết quả nếu DEBUG_MODE=true
  local status=$?
  if [[ "${DEBUG_MODE:-false}" == "true" ]]; then
    if [[ $status -eq 0 ]]; then
      echo -e "${green}[SOURCE]${reset} Sourced ${yellow}${target_file}${reset} thành công!"
    else
      echo -e "${red}[SOURCE ERROR]${reset} Sourced ${yellow}${target_file}${reset} thất bại với mã lỗi $status!"
    fi
  fi
  
  return $status
}

# === Auto-load config.sh
load_config_file