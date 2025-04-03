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
source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/wordpress_loader.sh"

# 📋 Hiển thị danh sách website để chọn (dùng select_website)
select_website
if [[ -z "$domain" ]]; then
  echo -e "${RED}${CROSSMARK} No website selected.${NC}"
  exit 1
fi

# === Cache Type Selection ===
echo -e "${YELLOW}📋 Please choose the cache type for $domain:${NC}"
echo -e "  ${GREEN}[1]${NC} WP Super Cache"
echo -e "  ${GREEN}[2]${NC} FastCGI Cache"
echo -e "  ${GREEN}[3]${NC} W3 Total Cache"
echo -e "  ${GREEN}[4]${NC} WP Fastest Cache"
echo -e "  ${GREEN}[5]${NC} No Cache"
echo ""

# Ask user to select a cache type
read -p "Select cache type (1-5): " cache_type_index

# Validate selection
case $cache_type_index in
    1) cache_type="wp-super-cache" ;;
    2) cache_type="fastcgi-cache" ;;
    3) cache_type="w3-total-cache" ;;
    4) cache_type="wp-fastest-cache" ;;
    5) cache_type="no-cache" ;;
    *) echo -e "${RED}${CROSSMARK} Invalid selection!${NC}" && exit 1 ;;
esac

echo -e "${GREEN}${CHECKMARK} Selected cache type: $cache_type${NC}"

# Call the logic function to set up the cache
wordpress_cache_setup_logic "$domain" "$cache_type"