safe_source "$CLI_DIR/website_create.sh"

# =====================================
# 🏗 website_create_command – Create a new website with WordPress
# ======================================
domain=${args[domain]}
php_version=${args[php]}
auto_generate=${args[auto_generate]}

website_cli_create --domain="$domain" \
    --php="$php_version" \
    --auto_generate="$auto_generate"
