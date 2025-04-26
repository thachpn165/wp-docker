#!/bin/bash
# ==================================================
# File: system_manage_docker.sh
# Description: Functions to manage Docker containers, including prompting the user to select 
#              a container and perform actions such as viewing logs or restarting the container.
# Functions:
#   - system_prompt_manage_docker: Prompt the user to manage a running Docker container.
#       Parameters: None.
#   - system_logic_manage_docker: Perform container actions (view logs or restart).
#       Parameters:
#           $1 - container_name: Name of the Docker container.
#           $2 - container_action: Action number (1=logs, 2=restart).
# ==================================================

system_prompt_manage_docker() {
  safe_source "$CLI_DIR/system_tools.sh"

  # Display running Docker containers
  print_msg info "$MSG_LIST_RUNNING_CONTAINERS"
  docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"

  # Prompt user to select container and action
  print_msg info "$PROMPT_ENTER_CONTAINER_NAME"
  read -r container_name

  print_msg info "$PROMPT_SELECT_CONTAINER_ACTION $container_name"
  echo -e "  ${GREEN}[1]${NC} ${LABEL_CONTAINER_ACTION_VIEW_LOG}"
  echo -e "  ${GREEN}[2]${NC} ${LABEL_CONTAINER_ACTION_RESTART}"
  read -r container_action
  print_msg info "$MSG_SELECT_OPTION (1-2)"

  # Call the CLI with selected parameters
  system_cli_manage_docker --container_name="$container_name" --action="$container_action"
}

system_logic_manage_docker() {
  local container_name="$1"
  local container_action="$2"

  if [[ -z "$container_name" || -z "$container_action" ]]; then
    print_and_debug error "$ERROR_CONTAINER_NAME_OR_ACTION_REQUIRED"
    return 1
  fi

  debug_log "[DOCKER MANAGE] Container: $container_name | Action: $container_action"

  case "$container_action" in
    1)
      # View container logs
      print_msg info "$(printf "$INFO_CONTAINER_LOG_STREAM" "$container_name")"
      docker logs -f "$container_name"
      ;;
    2)
      # Restart container
      print_msg step "$(printf "$STEP_CONTAINER_RESTARTING" "$container_name")"
      if docker restart "$container_name" &>/dev/null; then
        print_msg success "$(printf "$SUCCESS_CONTAINER_RESTARTED" "$container_name")"
      else
        print_and_debug error "$(printf "$ERROR_CONTAINER_RESTART_FAILED" "$container_name")"
        return 1
      fi
      ;;
    *)
      # Invalid action
      print_and_debug error "$ERROR_INVALID_ACTION_OPTION"
      return 1
      ;;
  esac
}