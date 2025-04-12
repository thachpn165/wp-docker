#!/usr/bin/env bash
# 🔧 Auto-detect BASE_DIR and load global configuration
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
  if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
    source "$SCRIPT_PATH/shared/config/load_config.sh"
    break
  fi
  SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done
safe_source "$FUNCTIONS_DIR/ssl_loader.sh"

# === Parse arguments ===
for arg in "$@"; do
  case $arg in
    --domain=*) domain="${arg#*=}" ;;
    --ssl_dir=*) SSL_DIR="${arg#*=}" ;;
  esac
done

# === Check if site_name is provided ===
if [[ -z "$domain" ]]; then
  #echo "${CROSSMARK} Missing required --domain parameter"
  print_and_debug error "$ERROR_MISSING_PARAM: --domain"
  exit 1
fi

# === Set default SSL_DIR if not provided ===
if [[ -z "$SSL_DIR" ]]; then
  SSL_DIR="$PROJECT_DIR/shared/ssl"
  debug_log "SSL_DIR not provided, using default: $SSL_DIR"
fi

# === Check SSL certificate status using the logic function ===
ssl_logic_check_cert "$domain" "$SSL_DIR"