#!/bin/bash
# ==================================================
# File: php_extensions.sh
# Description: CLI wrapper to manage PHP extensions, including installing extensions for specific domains.
# Functions:
#   - php_cli_install_extension: Install a PHP extension for a specific domain.
#       Parameters:
#           --domain=<domain>: The domain name where the extension will be installed.
#           --extension=<extension>: The PHP extension to install.
#       Returns: None.
# ==================================================

# Auto-detect BASE_DIR and load config
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
    if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
        source "$SCRIPT_PATH/shared/config/load_config.sh"

        load_config_file
        break
    fi
    SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done
safe_source "$FUNCTIONS_DIR/php_loader.sh"

php_cli_install_extension() {
    local domain extension
    domain=$(_parse_params "--domain" "$@")
    extension=$(_parse_params "--extension" "$@")

    php_logic_install_extension "$domain" "$extension"
}