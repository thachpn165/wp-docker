#!/bin/bash
# ✅ Load configuration from any directory
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
SEARCH_PATH="$SCRIPT_PATH"
while [[ "$SEARCH_PATH" != "/" ]]; do
  if [[ -f "$SEARCH_PATH/shared/config/load_config.sh" ]]; then
    source "$SEARCH_PATH/shared/config/load_config.sh"
    load_config_file
    break
  fi
  SEARCH_PATH="$(dirname "$SEARCH_PATH")"
done

# Load functions for website management
safe_source "$FUNCTIONS_DIR/website_loader.sh"
safe_source "$FUNCTIONS_DIR/wordpress_loader.sh"


# 📋 Hiển thị danh sách website để chọn (dùng select_website)
select_website
if [[ -z "$domain" ]]; then
  print_msg error "$ERROR_NO_WEBSITE_SELECTED"
  exit 1
fi

# === Cache Type Selection ===
print_msg title "$LABEL_MENU_MAIN_WORDPRESS_CACHE"
print_msg info "  ${GREEN}[1]${NC} WP Super Cache"
print_msg info "  ${GREEN}[2]${NC} FastCGI Cache"
print_msg info "  ${GREEN}[3]${NC} W3 Total Cache"
print_msg info "  ${GREEN}[4]${NC} WP Fastest Cache"
print_msg info "  ${GREEN}[5]${NC} No Cache"

cache_type_index=$(get_input_or_test_value "$PROMPT_WORDPRESS_CHOOSE_CACHE" "${TEST_CACHE_TYPE:-5}")

# Validate selection
case $cache_type_index in
    1) cache_type="wp-super-cache" ;;
    2) cache_type="fastcgi-cache" ;;
    3) cache_type="w3-total-cache" ;;
    4) cache_type="wp-fastest-cache" ;;
    5) cache_type="no-cache" ;;
    *) print_msg error "$ERROR_SELECT_OPTION_INVALID" && exit 1 ;;
esac

print_msg success "$SUCCESS_WORDPRESS_CHOOSE_CACHE: $cache_type"

# Call the logic function to set up the cache
wordpress_cache_setup_logic "$domain" "$cache_type"