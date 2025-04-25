#!/bin/bash
# =====================================
# 🔐 ssl_cli_install – CLI wrapper for SSL installation methods
# =====================================

# === Auto-detect BASE_DIR & load config ===
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
    if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
        source "$SCRIPT_PATH/shared/config/load_config.sh"
        break
    fi
    SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done

# === Load SSL logic functions ===
safe_source "$FUNCTIONS_DIR/ssl_loader.sh"

# =====================================
# 🔒 ssl_cli_install_selfsigned
# Parameters: --domain
# =====================================
ssl_cli_install_selfsigned() {
    local domain
    domain=$(_parse_params "--domain" "$@")

    _is_missing_param "$domain" "--domain" || return 1
    _is_valid_domain "$domain" || return 1

    ssl_logic_install_selfsigned "$domain"
}

# =====================================
# 🔐 ssl_cli_install_ssl_prompt_general
# Parameters: --domain --email [--staging]
# =====================================
ssl_cli_install_letsencrypt() {
    local domain email staging

    domain=$(_parse_params "--domain" "$@")
    email=$(_parse_params "--email" "$@")
    staging=$(_parse_optional_params "--staging" "$@")

    _is_missing_param "$domain" "--domain" || return 1
    _is_missing_param "$email" "--email" || return 1
    _is_valid_domain "$domain" || return 1
    _is_valid_email "$email" || return 1

    ssl_logic_install_letsencrypt "$domain" "$email" "$staging"
}

# =====================================
# 📄 ssl_cli_install_manual
# Parameters: --domain
# =====================================
ssl_cli_install_manual() {
    local domain
    domain=$(_parse_params "--domain" "$@")

    _is_missing_param "$domain" "--domain" || return 1
    _is_valid_domain "$domain" || return 1

    ssl_logic_install_manual "$domain"
}
