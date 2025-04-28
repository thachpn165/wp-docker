#!/bin/bash
# ==================================================
# File: system_tools.sh
# Description: CLI wrappers for system-level operations, including viewing system resources, 
#              managing Docker containers, cleaning up Docker resources, and rebuilding NGINX Proxy.
# Functions:
#   - system_cli_check_resources: View system resource usage.
#       Parameters: None.
#       Returns: None.
#   - system_cli_manage_docker: Manage a Docker container (logs, restart).
#       Parameters:
#           --container_name=<name>: The name of the Docker container.
#           --action=<action>: The action to perform (e.g., logs, restart).
#       Returns: None.
#   - system_cli_cleanup_docker: Remove unused Docker resources.
#       Parameters: None.
#       Returns: None.
#   - system_cli_nginx_rebuild: Rebuild the NGINX Proxy container.
#       Parameters: None.
#       Returns: None.
# ==================================================

# === Auto-detect BASE_DIR and load config ===
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
    if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
        source "$SCRIPT_PATH/shared/config/load_config.sh"
        break
    fi
    SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done

# === Load system logic functions ===
safe_source "$FUNCTIONS_DIR/system_loader.sh"

system_cli_check_resources() {
    system_logic_check_resources
}

system_cli_manage_docker() {
    local container_name container_action

    container_name=$(_parse_params "--container_name" "$@")
    container_action=$(_parse_params "--action" "$@")

    _is_missing_param "$container_name" "--container_name" || return 1
    _is_missing_param "$container_action" "--action" || return 1

    system_logic_manage_docker "$container_name" "$container_action"
}

system_cli_cleanup_docker() {
    system_logic_cleanup_docker
}

system_cli_nginx_rebuild() {
    system_logic_nginx_rebuild
}