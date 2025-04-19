cron_register_loader_if_needed() {
    local cron_line="*/5 * * * * bash $CORE_DIR/crons/cron_loader.sh"

    # Lấy nội dung crontab hiện tại
    local current_cron
    current_cron=$(crontab -l 2>/dev/null || true)

    # Kiểm tra xem dòng đã tồn tại chưa
    if echo "$current_cron" | grep -Fq "$CORE_DIR/crons/cron_loader.sh"; then
        print_msg info "🕒 cron_loader.sh is already registered in crontab"
        return 0
    fi

    # Thêm vào crontab
    (
        echo "$current_cron"
        echo "$cron_line"
    ) | crontab -

    print_msg success "✅ Added cron_loader.sh to system crontab (every 5 minutes)"
}
