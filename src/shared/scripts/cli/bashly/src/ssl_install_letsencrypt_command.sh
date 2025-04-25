safe_source "$CLI_DIR/ssl_install.sh"

ssl_cli_install_letsencrypt --domain="${args[domain]}" \
                            --email="${args[email]}" \
                            --staging="${args[staging]}"