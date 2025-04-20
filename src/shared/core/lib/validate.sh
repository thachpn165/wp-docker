# =============================================
# 🌐 _is_valid_domain – Validate a domain name format
# ---------------------------------------------
# Usage:
#   if ! _is_valid_domain "$domain"; then ...
# =============================================
_is_valid_domain() {
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

# =============================================
# ⚠️ _is_missing_param – Check if required param is missing
# ---------------------------------------------
# Usage:
#   _is_missing_param "$var" "--domain" || return 1
# =============================================
_is_missing_param() {
    local value="$1"
    local label="$2"

    if [[ -z "$value" || "$value" == "$label" ]]; then
        print_and_debug error "$ERROR_MISSING_PARAM: $label"
        return 1
    fi
}

# =============================================
# 📧 _is_valid_email – Validate email address format
# ---------------------------------------------
# Usage:
#   _is_valid_email "$email" || return 1
# =============================================
_is_valid_email() {
    local email="$1"

    if [[ -z "$email" ]]; then
        print_msg error "❌ Email is required."
        return 1
    fi

    # RFC 5322-compliant basic pattern, accepts name@domain.com or name@domain.com.vn
    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        print_msg error "❌ Invalid email format: $email"
        return 1
    fi

    return 0
}
