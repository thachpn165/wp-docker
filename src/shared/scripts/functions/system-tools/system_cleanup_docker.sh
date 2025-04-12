system_logic_cleanup_docker() {
  if ! command -v docker &> /dev/null; then
    print_and_debug error "$ERROR_DOCKER_NOT_INSTALLED"
    return 1
  fi

  print_msg step "$STEP_DOCKER_CLEANUP_START"
  run_cmd "docker system prune -af --volumes"

  print_msg step "$STEP_DOCKER_REMOVE_UNUSED_NETWORKS"
  run_cmd "docker network prune -f"

  print_msg success "$SUCCESS_DOCKER_CLEANUP_DONE"
}