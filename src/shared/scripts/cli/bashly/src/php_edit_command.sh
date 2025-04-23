safe_source "$FUNCTIONS_DIR/php_loader.sh"

# Check if ${args[config_type]} is "conf" or "ini"
if [[ "${args[config_type]}" == "conf" ]]; then
    # If it's "conf", use edit_php_fpm_conf
    edit_php_fpm_conf || exit 1
elif [[ "${args[config_type]}" == "ini" ]]; then
    edit_php_ini || exit 1
else
    # If it's neither, print an error message
    print_msg error "Invalid config type: ${args[config_type]}. Use 'conf' or 'ini'."
    exit 1
fi