safe_source "$FUNCTIONS_DIR/core/core_version_management.sh"


current_channel=$(core_channel_get)

print_msg info "Current channel: $current_channel"
