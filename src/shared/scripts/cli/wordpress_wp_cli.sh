#!/bin/bash
# ======================================
# CLI wrapper: Run WP-CLI inside container for a given site
# ======================================

# === Load config & loader ===
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
source "$FUNCTIONS_DIR/wordpress_loader.sh"

# === Parse arguments ===
domain=""
params=()

for arg in "$@"; do
  case $arg in
    --domain=*) domain="${arg#*=}" ;;
    *) params+=("$arg") ;;
  esac
done

if [[ -z "$domain" ]]; then
  echo -e "${RED}${CROSSMARK} Missing required --domain=SITE_DOMAIN parameter.${NC}"
  echo "Usage: $0 --domain=SITE_DOMAIN wp-cli-commands..."
  exit 1
fi

if [[ ${#params[@]} -eq 0 ]]; then
  echo -e "${RED}${CROSSMARK} You must provide a WP-CLI command to run.${NC}"
  echo "Example: $0 --domain=wpdocker.dev plugin list"
  exit 1
fi

# === Call logic ===
wordpress_wp_cli_logic "$domain" "${params[@]}"