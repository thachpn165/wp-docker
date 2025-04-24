safe_source "$CLI_DIR/wordpress_cache_setup.sh"

wordpress_cli_cache_setup --domain="${args[domain]}" --cache_type="${args[--type]}" || exit 1