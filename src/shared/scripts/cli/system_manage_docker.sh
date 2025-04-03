#!/bin/bash
# This script is used to manage Docker containers within a project environment.
# It ensures the script is executed in a Bash shell, determines the project directory,
# loads necessary configuration files, and processes command-line arguments to perform
# Docker container management actions.

# === Script Overview ===
# 1. Validates that the script is run in a Bash shell.
# 2. Determines the PROJECT_DIR by searching for the 'config.sh' file in the directory hierarchy.
# 3. Loads the configuration file and additional required scripts.
# 4. Parses command-line arguments to extract the container name and action.
# 5. Calls the `system_manage_docker_logic` function to perform the specified action on the container.

# === Command-Line Arguments ===
# --container_name=<name>   : Specifies the name of the Docker container to manage.
# --container_action=<action>: Specifies the action to perform on the container (e.g., start, stop, restart).

# === Prerequisites ===
# - The script must be executed in a Bash shell.
# - The PROJECT_DIR environment variable must be set or determinable by locating 'config.sh'.
# - The 'config.sh' file must exist in the expected directory structure.
# - The `system_manage_docker_logic` function must be defined in the sourced scripts.

# === Error Handling ===
# - Exits with an error if the script is not run in a Bash shell.
# - Exits with an error if the PROJECT_DIR cannot be determined or the config file is missing.
# - Exits with an error if required parameters (--container_name and --container_action) are not provided.
# - Exits with an error if an unknown parameter is passed.

# === Usage Example ===
# ./system_manage_docker.sh --container_name=my_container --container_action=start

# Ensure PROJECT_DIR is set
if [[ -z "$PROJECT_DIR" ]]; then
  SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
  
  # Iterate upwards from the current script directory to find 'config.sh'
  while [[ "$SCRIPT_PATH" != "/" ]]; do
    if [[ -f "$SCRIPT_PATH/shared/config/config.sh" ]]; then
      PROJECT_DIR="$SCRIPT_PATH"
      break
    fi
    SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
  done

  # Handle error if config file is not found
  if [[ -z "$PROJECT_DIR" ]]; then
    echo "${CROSSMARK} Unable to determine PROJECT_DIR. Please check the script's directory structure." >&2
    exit 1
  fi
fi

# Load the config file if PROJECT_DIR is set
CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "${CROSSMARK} Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi

# Source the config file
source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/system_loader.sh"

# === Parse command line flags ===
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --container_name=*)
      container_name="${1#*=}"
      ;;
    --container_action=*)
      container_action="${1#*=}"
      ;;
    *)
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
  shift
done

# Check if the required parameters are provided
if [[ -z "$container_name" || -z "$container_action" ]]; then
  echo "${CROSSMARK} Missing required parameters: --container_name and --container_action"
  exit 1
fi

# === Call the logic function to manage Docker containers ===
system_manage_docker_logic "$container_name" "$container_action"