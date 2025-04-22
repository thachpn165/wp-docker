#shellcheck disable=SC2154
source "$CLI_DIR/website_create.sh"

website_cli_create --domain="${args[domain]}" --php="${args[php]}"