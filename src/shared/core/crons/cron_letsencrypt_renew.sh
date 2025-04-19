cron_letsencrypt_renew() {
    print_msg title "$TITLE_SSL_LETSCERTIFICATE_RENEWAL"

    if [[ -z "$SITES_DIR" ]]; then
        print_msg error "SITES_DIR is not defined."
        return 1
    fi

    local site domain cert_path issuer expire_date expire_ts now_ts remaining_days log_file site_path

    while IFS= read -r site; do
        site_path="$SITES_DIR/$site"
        domain="$(json_get_site_value "$site" "DOMAIN")"
        log_file="$site_path/logs/ssl-renew.log"

        print_msg info "🔍 Checking: $domain ($site)"

        # Ensure log file and its directory exist
        mkdir -p "$(dirname "$log_file")"
        touch "$log_file"

        cert_path="$SSL_DIR/$domain.crt"
        if [[ ! -f "$cert_path" ]]; then
            formatted_not_found_cert="$(printf "$ERROR_SSL_CERT_NOT_FOUND" "$domain")"
            print_msg error "$formatted_not_found_cert"
            echo "$(date '+%F %T') ❌ Certificate not found: $domain" >>"$log_file"
            continue
        fi

        # Check if certificate is issued by Let's Encrypt
        issuer=$(openssl x509 -issuer -noout -in "$cert_path" 2>/dev/null)
        if ! echo "$issuer" | grep -qi "Let's Encrypt"; then
            print_msg warning "$domain $WARNING_SSL_NOT_LETSENCRYPT"
            echo "$(date '+%F %T') ⚠️ Not Let's Encrypt cert: $domain (issuer: $issuer)" >>"$log_file"
            continue
        fi

        # Check certificate expiration
        expire_date=$(openssl x509 -enddate -noout -in "$cert_path" 2>/dev/null | cut -d= -f2)
        expire_ts=$(date -d "$expire_date" +%s 2>/dev/null || gdate -d "$expire_date" +%s)
        now_ts=$(date +%s)
        remaining_days=$(((expire_ts - now_ts) / 86400))

        debug_log "[cron_letsencrypt_renew] $domain: $remaining_days days remaining"

        if ((remaining_days <= 3)); then
            formatted_renewing_cert="$(printf "$STEP_SSL_LETSENCRYPT_RENEWING" "$domain" "$remaining_days")"
            print_msg step "$formatted_renewing_cert"

            certbot certonly --quiet --non-interactive --renew-by-default --webroot \
                -w "$site_path/wordpress" -d "$domain" >>"$log_file" 2>&1

            if [[ $? -eq 0 ]]; then
                print_msg success "$SUCCESS_SSL_LETSENCRYPT_RENEWED: $domain"
                echo "$(date '+%F %T') ✅ Renewed: $domain" >>"$log_file"
                nginx_reload
            else
                print_msg error "$ERROR_SSL_LETSENCRYPT_RENEW_FAILED: $domain"
                print_msg important "$IMPORTANT_CHECK_LOG: $log_file"
                echo "$(date '+%F %T') ❌ Failed to renew: $domain" >>"$log_file"
            fi
        else
            print_msg info "✅ Certificate still valid for $domain ($remaining_days days left)"
            echo "$(date '+%F %T') ⏳ Still valid: $domain ($remaining_days days left)" >>"$log_file"
        fi
    done < <(website_list)
}
