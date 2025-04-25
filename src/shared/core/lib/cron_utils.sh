cron_register_loader_if_needed() {
    _is_missing_var "$CORE_DIR" "CORE_DIR" || return 1
    local cron_line="*/5 * * * * bash $CORE_DIR/crons/cron_loader.sh"

    if ! command -v crontab &>/dev/null; then
        print_msg error "$ERROR_CRONTAB_NOT_AVAILABLE"
        return 1
    fi
    # Lấy nội dung crontab hiện tại
    local current_cron
    current_cron=$(crontab -l 2>/dev/null || true)

    # Kiểm tra xem dòng đã tồn tại chưa
    if echo "$current_cron" | grep -Fq "$CORE_DIR/crons/cron_loader.sh"; then
        print_msg info "$SUCCESS_CRON_LOADER_ALREADY_ADDED"
        return 0
    fi

    (
        echo "$current_cron"
        echo "$cron_line"
    ) | crontab - || {
        print_msg error "$ERROR_CRON_LOADER_NOT_ADDED"
        return 1
    }

    print_msg success "$SUCCESS_CRON_LOADER_ADDED"
}
