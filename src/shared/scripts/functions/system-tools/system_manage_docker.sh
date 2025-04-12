system_prompt_manage_docker() {
  safe_source "$CLI_DIR/system_tools.sh"
  # === Display running Docker containers ===
  echo -e "${YELLOW}🚀 List of running Docker containers:${NC}"
  docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"

  # === Prompt to select a container and action ===
  echo -e "${YELLOW}📑 Enter the container name from the list above:${NC}"
  read -r container_name

  echo -e "${YELLOW}📑 Select an action to perform on container '$container_name':"
  echo -e "  ${GREEN}[1]${NC} View logs"
  echo -e "  ${GREEN}[2]${NC} Restart container"
  echo -n "Enter your choice (1 or 2): "
  read -r container_action

  # === Call the CLI with the selected parameters ===
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
    print_msg info "$(printf "$INFO_CONTAINER_LOG_STREAM" "$container_name")"
    docker logs -f "$container_name"
    ;;
  2)
    print_msg step "$(printf "$STEP_CONTAINER_RESTARTING" "$container_name")"
    if docker restart "$container_name" &>/dev/null; then
      print_msg success "$(printf "$SUCCESS_CONTAINER_RESTARTED" "$container_name")"
    else
      print_and_debug error "$(printf "$ERROR_CONTAINER_RESTART_FAILED" "$container_name")"
      return 1
    fi
    ;;
  *)
    print_and_debug error "$ERROR_INVALID_ACTION_OPTION"
    return 1
    ;;
  esac
}
