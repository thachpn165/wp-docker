# =============================================
# 🌐 is_valid_domain – Validate a domain name format
# ---------------------------------------------
# Usage:
#   if ! is_valid_domain "$domain"; then ...
# =============================================
is_valid_domain() {
    local domain="$1"

    # Empty check
    if [[ -z "$domain" ]]; then
        print_msg error "$ERROR_DOMAIN_EMPTY"
        return 1
    fi

    # Must match standard domain pattern: sub.domain.tld
    if ! [[ "$domain" =~ ^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$ ]]; then
        print_msg error "$(printf "$ERROR_DOMAIN_INVALID_FORMAT" "$domain")"
        return 1
    fi

    # Optional: disallow domain starting or ending with hyphen
    if [[ "$domain" =~ (^[-])|([-]$) ]]; then
        print_msg error "$(printf "$ERROR_DOMAIN_INVALID_HYPHEN" "$domain")"
        return 1
    fi

    return 0
}
