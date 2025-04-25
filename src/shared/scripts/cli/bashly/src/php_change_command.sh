safe_source "$CLI_DIR/php_version.sh"

php_cli_change_version --domain="${args[domain]}" --php_version="${args[version]}" || exit 1