#!/bin/bash
# 🔧 Auto-detect BASE_DIR and load global configuration
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
    if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
        source "$SCRIPT_PATH/shared/config/load_config.sh"
        break
    fi
    SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done
safe_source "$FUNCTIONS_DIR/system_loader.sh"

system_cli_check_resources() {
    system_logic_check_resources
}

system_cli_manage_docker() {
    local container_name
    container_name=$(_parse_params "--container_name" "$@")
    local container_action
    container_action=$(_parse_params "--action" "$@")

    if [[ -z "$container_name" || -z "$container_action" ]]; then
        print_and_debug error "$ERROR_CONTAINER_NAME_OR_ACTION_REQUIRED"
        print_and_debug info "$INFO_PARAM_EXAMPLE:\n  --container_name=nginx\n  --action=1/2\n"
        exit 1
    fi
    system_logic_manage_docker "$container_name" "$container_action"
}

system_cli_cleanup_docker() {
    system_logic_cleanup_docker
}

system_cli_nginx_rebuild() {
    system_logic_nginx_rebuild
}