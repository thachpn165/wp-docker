cron_letsencrypt_renew() {
    print_msg title "🔄 Auto-renew Let's Encrypt SSL for all sites"

    if [[ -z "$SITES_DIR" ]]; then
        print_msg error "SITES_DIR is not defined."
        return 1
    fi

    local site ssl_type cert_path domain expire_date expire_ts now_ts remaining_days log_file site_path

    while IFS= read -r site; do
        site_path="$SITES_DIR/$site"
        log_file="$site_path/logs/ssl-renew.log"
        domain="$(json_get_site_value "$site" "DOMAIN")"
        ssl_type="$(json_get_site_value "$site" "SSL.TYPE")"

        if [[ "$ssl_type" != "letsencrypt" ]]; then
            debug_log "[cron_letsencrypt_renew] Skip $site: Not using Let's Encrypt"
            continue
        fi

        cert_path="/etc/letsencrypt/live/$domain/fullchain.pem"
        if [[ ! -f "$cert_path" ]]; then
            print_msg warning "⚠️ Không tìm thấy chứng chỉ cho $domain ($cert_path)"
            continue
        fi

        # Kiểm tra ngày hết hạn
        expire_date=$(openssl x509 -enddate -noout -in "$cert_path" 2>/dev/null | cut -d= -f2)
        expire_ts=$(date -d "$expire_date" +%s 2>/dev/null || gdate -d "$expire_date" +%s)
        now_ts=$(date +%s)
        remaining_days=$(((expire_ts - now_ts) / 86400))

        debug_log "[cron_letsencrypt_renew] $domain: $remaining_days ngày còn lại"

        if ((remaining_days <= 3)); then
            print_msg info "🔄 Đang gia hạn SSL cho $domain (Còn $remaining_days ngày)"
            certbot certonly --quiet --non-interactive --renew-by-default --webroot -w "$site_path/html" -d "$domain" >>"$log_file" 2>&1

            if [[ $? -eq 0 ]]; then
                print_msg success "✅ Gia hạn SSL thành công cho $domain"
                echo "$(date '+%F %T') ✅ Renewed: $domain" >>"$log_file"
            else
                print_msg error "❌ Gia hạn SSL thất bại cho $domain"
                echo "$(date '+%F %T') ❌ Failed to renew: $domain" >>"$log_file"
            fi

            nginx_reload
        fi
    done < <(website_list)
}
cron_letsencrypt_renew