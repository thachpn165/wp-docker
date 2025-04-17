wordpress_prompt_auto_update_plugin() {
    local domain 
    # 📋 Select website
    website_get_selected domain
    if [[ -z "$domain" ]]; then
        print_msg error "$ERROR_SITE_NOT_SELECTED"
        exit 1
    fi

    # 📋 Prompt action
    print_msg info "$(printf "$PROMPT_CHOOSE_ACTION_FOR_SITE" "$domain")"
    echo "1) $LABEL_ENABLE_AUTO_UPDATE_PLUGIN"
    echo "2) $LABEL_DISABLE_AUTO_UPDATE_PLUGIN"

    action_choice=$(get_input_or_test_value "$PROMPT_ENTER_OPTION" "${TEST_ACTION_CHOICE:-1}")
    if [[ "$action_choice" == "1" ]]; then
        action="enable"
    elif [[ "$action_choice" == "2" ]]; then
        action="disable"
    else
        print_msg error "$ERROR_SELECT_OPTION_INVALID"
        exit 1
    fi

    # ▶️ Execute CLI
    #bash "$SCRIPTS_DIR/cli/wordpress_auto_update_plugin.sh" --domain="$domain" --action="$action"
    wordpress_cli_auto_update_plugin --domain="$domain" --action="$action"
}
# =====================================
# wordpress_auto_update_plugin_logic: Enable or disable auto-updates for all plugins
# Parameters:
#   $1 - domain (site name)
#   $2 - action (enable|disable)
# Behavior:
#   - Executes WP-CLI command to toggle plugin auto-updates
#   - Displays plugin list with auto_update status after action
# =====================================
wordpress_auto_update_plugin_logic() {

    domain="$1" # site_name will be passed from the menu file or CLI

    # **Handle enabling/disabling automatic plugin updates**
    if [[ "$2" == "enable" ]]; then
        print_msg info "$LABEL_ENABLE_AUTO_UPDATE_PLUGIN"
        bash "$CLI_DIR/wordpress_wp_cli.sh" --domain="${domain}" -- plugin auto-updates enable --all
        exit_if_error "$?" "Unable to enable automatic updates for plugins on '$domain'."
        print_msg success "$(printf "$SUCCESS_PLUGIN_AUTO_UPDATE_ENABLED" "$domain")"
    elif [[ "$2" == "disable" ]]; then
        print_msg info "$LABEL_DISABLE_AUTO_UPDATE_PLUGIN"
        bash "$CLI_DIR/wordpress_wp_cli.sh" --domain="${domain}" -- plugin auto-updates disable --all
        exit_if_error "$?" "Unable to disable automatic updates for plugins on '$domain'."
        print_msg success "$(printf "$SUCCESS_PLUGIN_AUTO_UPDATE_DISABLED" "$domain")"
    else
        print_msg error "$ERROR_INVALID_CHOICE"
        exit 1
    fi

    print_msg info "$(printf "$INFO_PLUGIN_STATUS" "$domain")"
    bash "$CLI_DIR/wordpress_wp_cli.sh" --domain="${domain}" -- plugin list --fields=name,status,auto_update --format=table
}
