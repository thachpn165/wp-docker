#!/bin/bash

# Ensure PROJECT_DIR is set
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
    print_msg error "Unable to determine PROJECT_DIR. Please check the script's directory structure."
    exit 1
  fi
fi

# Load and source the config file
CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  print_msg error "Config file not found at: $CONFIG_FILE"
  exit 1
fi
source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/wordpress_loader.sh"

# 📋 Hiển thị danh sách website để chọn (dùng select_website)
select_website
if [[ -z "$domain" ]]; then
  print_msg error "$ERROR_NO_WEBSITE_SELECTED"
  exit 1
fi

# === Cache Type Selection ===
print_msg title "$(printf "$PROMPT_CHOOSE_ACTION_FOR_SITE" "$domain")"
print_msg info "  ${GREEN}[1]${NC} WP Super Cache"
print_msg info "  ${GREEN}[2]${NC} FastCGI Cache"
print_msg info "  ${GREEN}[3]${NC} W3 Total Cache"
print_msg info "  ${GREEN}[4]${NC} WP Fastest Cache"
print_msg info "  ${GREEN}[5]${NC} No Cache"

get_input_or_test_value "$PROMPT_SELECT_OPTION" cache_type_index

# Validate selection
case $cache_type_index in
    1) cache_type="wp-super-cache" ;;
    2) cache_type="fastcgi-cache" ;;
    3) cache_type="w3-total-cache" ;;
    4) cache_type="wp-fastest-cache" ;;
    5) cache_type="no-cache" ;;
    *) print_msg error "$ERROR_SELECT_OPTION_INVALID" && exit 1 ;;
esac

print_msg success "Selected cache type: $cache_type"

# Call the logic function to set up the cache
wordpress_cache_setup_logic "$domain" "$cache_type"