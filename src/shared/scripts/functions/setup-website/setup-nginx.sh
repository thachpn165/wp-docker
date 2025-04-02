#!/bin/bash

# =====================================
# 🐳 Create NGINX configuration file from available environment variables
# =====================================
# === Auto-detect PROJECT_DIR ===
if [[ -z "$PROJECT_DIR" ]]; then
  SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
  while [[ "$SCRIPT_PATH" != "/" ]]; do
    if [[ -f "$SCRIPT_PATH/shared/config/config.sh" ]]; then
      PROJECT_DIR="$SCRIPT_PATH"
      break
    fi
    SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
  done
fi

CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "${CROSSMARK} Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi
source "$CONFIG_FILE"


# ${CHECKMARK} Check if input variables exist
if [[ -z "$site_name" || -z "$domain" ]]; then
    echo -e "${RED}${CROSSMARK} Missing environment variables site_name or domain. Please export before calling the script.${NC}"
    exit 1
fi

# Check if target directory exists (NGINX conf)
NGINX_CONF_DIR="$NGINX_PROXY_DIR/conf.d"
is_directory_exist "$NGINX_CONF_DIR"

# Create nginx configuration file from template
NGINX_TEMPLATE="$TEMPLATES_DIR/nginx-proxy.conf.template"
NGINX_CONF="$NGINX_CONF_DIR/$site_name.conf"

# If NGINX configuration file exists, remove it before creating new one
if is_file_exist "$NGINX_CONF"; then
    echo -e "${YELLOW}🗑️ Removing old NGINX configuration: $NGINX_CONF${NC}"
    rm -f "$NGINX_CONF"
fi

# Check if NGINX template exists
if is_file_exist "$NGINX_TEMPLATE"; then
    # Check if template directory exists
    if [ ! -d "$(dirname "$NGINX_TEMPLATE")" ]; then
        echo -e "${RED}${CROSSMARK} NGINX template directory does not exist: $(dirname "$NGINX_TEMPLATE")${NC}"
        exit 1
    fi

    # Create a copy of NGINX template and replace variables
    cp "$NGINX_TEMPLATE" "$NGINX_CONF" || { echo -e "${RED}${CROSSMARK} Could not copy NGINX template.${NC}"; exit 1; }
    sedi "s|\\\${SITE_NAME}|$site_name|g" "$NGINX_CONF"
    sedi "s|\\\${DOMAIN}|$domain|g" "$NGINX_CONF"
    sedi "s|\\\${PHP_CONTAINER}|$site_name-php|g" "$NGINX_CONF"

    echo -e "${GREEN}${CHECKMARK} Created NGINX file: $NGINX_CONF${NC}"
else
    echo -e "${RED}${CROSSMARK} NGINX template not found: $NGINX_TEMPLATE${NC}"
    exit 1
fi
