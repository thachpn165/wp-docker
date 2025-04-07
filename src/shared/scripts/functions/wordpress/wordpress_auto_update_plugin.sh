wordpress_auto_update_plugin_logic() {

    domain="$1"  # site_name will be passed from the menu file or CLI

    SITE_DIR="$SITES_DIR/$domain"
    PHP_CONTAINER="$domain-php"
    
    # **Handle enabling/disabling automatic plugin updates**
    if [[ "$2" == "enable" ]]; then
        print_msg info "$LABEL_ENABLE_AUTO_UPDATE_PLUGIN"
        bash "$CLI_DIR/wordpress_wp_cli.sh" --domain="${domain}" -- plugin auto-updates enable --all
        exit_if_error "$?" "Unable to enable automatic updates for plugins on '$domain'."
        print_msg success "Đã bật tự động cập nhật plugin cho website '$domain'."
    elif [[ "$2" == "disable" ]]; then
        print_msg info "$LABEL_DISABLE_AUTO_UPDATE_PLUGIN"
        bash "$CLI_DIR/wordpress_wp_cli.sh" --domain="${domain}" -- plugin auto-updates disable --all
        exit_if_error "$?" "Unable to disable automatic updates for plugins on '$domain'."
        print_msg success "Đã tắt tự động cập nhật plugin cho website '$domain'."
    else
        print_msg error "$ERROR_INVALID_CHOICE"
        exit 1
    fi
    
    print_msg info "📋 Trạng thái plugin hiện tại trên '$domain':"
    bash "$CLI_DIR/wordpress_wp_cli.sh" --domain="${domain}" -- plugin list --fields=name,status,auto_update --format=table

}