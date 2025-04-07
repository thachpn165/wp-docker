#!/bin/bash

#echo -e "${BLUE}===== CREATE NEW WORDPRESS WEBSITE =====${NC}"
print_msg title "$TITLE_CREATE_NEW_WORDPRESS_WEBSITE"
# Lấy domain từ người dùng
read -p "$PROMPT_ENTER_DOMAIN: " domain

php_choose_version || return 1
php_version="$REPLY"

echo ""
choice=$(get_input_or_test_value "$PROMPT_WEBSITE_CREATE_RANDOM_ADMIN" "${TEST_WEBSITE_CREATE_RANDOM_ADMIN:-y}")
echo "🔍 Prompt text: $PROMPT_WEBSITE_CREATE_RANDOM_ADMIN"
choice="$(echo "$choice" | tr '[:upper:]' '[:lower:]')"

auto_generate=true
[[ "$choice" == "n" ]] && auto_generate=false

print_and_debug "🐝 PHP version: $php_version"
print_and_debug "🐝 Domain: $domain"

bash "$SCRIPTS_DIR/cli/website_create.sh" \
  --domain="$domain" \
  --php="$php_version" \
  --auto_generate="$auto_generate" || return 1

