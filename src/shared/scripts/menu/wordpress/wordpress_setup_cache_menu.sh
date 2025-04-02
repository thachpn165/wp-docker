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
    echo "❌ Unable to determine PROJECT_DIR. Please check the script's directory structure." >&2
    exit 1
  fi
fi

# Load the config file if PROJECT_DIR is set
CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi

# Source the config file
source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/wordpress_loader.sh"

# === Display Website Selection ===
echo -e "${YELLOW}📋 Please choose the website for cache setup:${NC}"

# Fetch all websites
site_list=($(ls -1 "$SITES_DIR"))

# Check if there are any websites
if [[ ${#site_list[@]} -eq 0 ]]; then
  echo -e "${RED}❌ No websites found.${NC}"
  exit 1
fi

# Display list of websites
for i in "${!site_list[@]}"; do
  echo -e "  ${GREEN}[$i]${NC} ${site_list[$i]}"
done

# Ask user to select a website
echo -e "${YELLOW}🔹 Select the website (enter the number):${NC}"
read -p "Website number: " site_index

# Check if the selection is valid
if [[ -z "${site_list[$site_index]}" ]]; then
  echo -e "${RED}❌ Invalid website selection.${NC}"
  exit 1
fi

site_name="${site_list[$site_index]}"
echo -e "${GREEN}✅ Selected website: $site_name${NC}"

# === Cache Type Selection ===
echo -e "${YELLOW}📋 Please choose the cache type for $site_name:${NC}"
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
    *) echo -e "${RED}❌ Invalid selection!${NC}" && exit 1 ;;
esac

echo -e "${GREEN}✅ Selected cache type: $cache_type${NC}"

# Call the logic function to set up the cache
wordpress_cache_setup_logic "$site_name" "$cache_type"