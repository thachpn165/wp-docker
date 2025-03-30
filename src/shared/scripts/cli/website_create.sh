#!/usr/bin/env bash

# === Auto-detect PROJECT_DIR (source code root) ===
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
  echo "❌ Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi
source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/website_loader.sh"

# === Input handling ===
auto_generate=true   # default: true
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --site_name=*) site_name="${1#*=}" ;;
    --domain=*) domain="${1#*=}" ;;
    --php=*) php_version="${1#*=}" ;;
    --auto_generate=*) auto_generate="${1#*=}" ;;
    *) echo "❌ Unknown option: $1" ; exit 1 ;;
  esac
  shift
done
#echo "📦 DEBUG: site=$site_name domain=$domain php=$php_version auto_generate=$auto_generate"
if [[ -z "$site_name" || -z "$domain" || -z "$php_version" ]]; then
  echo "❌ Missing parameters. Usage:"
  echo "  $0 --site_name=abc --domain=abc.com --php=8.2"
  exit 1
fi

website_management_create_logic "$site_name" "$domain" "$php_version"
website_setup_wordpress_logic "$site_name" "$auto_generate"

echo "✅ DONE_CREATE_WEBSITE: $site_name"