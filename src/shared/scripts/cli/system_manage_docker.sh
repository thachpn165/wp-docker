#!/bin/bash

# === Load config & system_loader.sh ===
if [[ -z "$PROJECT_DIR" ]]; then
  SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
  while [[ "$SCRIPT_PATH" != "/" ]]; do
    if [[ -f "$SCRIPT_PATH/shared/config/config.sh" ]]; then
      PROJECT_DIR="$SCRIPT_PATH"
      break
    fi
    SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
  done
fi

CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi
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
  echo "❌ Missing required parameters: --container_name and --container_action"
  exit 1
fi

# === Call the logic function to manage Docker containers ===
system_manage_docker_logic "$container_name" "$container_action"