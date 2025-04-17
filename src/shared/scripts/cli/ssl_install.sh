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

    if [[ -z "$domain" ]]; then
        print_and_debug error "$ERROR_MISSING_PARAM: --domain"
        print_and_debug info "$INFO_PARAM_EXAMPLE:\n  --domain=example.tld"
        exit 1
    fi

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

    if [[ -z "$domain" || -z "$email" ]]; then
        print_and_debug error "$ERROR_MISSING_PARAM: --domain, --email"
        print_and_debug info "$INFO_PARAM_EXAMPLE:\n  --domain=example.tld --email=contact@yourdomain"
        exit 1
    fi

    ssl_logic_install_letsencrypt "$domain" "$email" "$staging"
}

# =====================================
# 📄 ssl_cli_install_manual
# Parameters: --domain
# =====================================
ssl_cli_install_manual() {
    local domain
    domain=$(_parse_params "--domain" "$@")

    if [[ -z "$domain" ]]; then
        print_and_debug error "$ERROR_MISSING_PARAM: --domain"
        print_and_debug info "$INFO_PARAM_EXAMPLE:\n  --domain=example.tld"
        exit 1
    fi

    ssl_logic_install_manual "$domain"
}
