safe_source "$CLI_DIR/ssl_install.sh"

ssl_cli_install_selfsigned --domain="${args[domain]}"
