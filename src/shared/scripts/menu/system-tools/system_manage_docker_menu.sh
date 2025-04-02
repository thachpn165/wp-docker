#!/usr/bin/env bash

# ============================================
# ✅ Docker Container Management Menu
# ============================================

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
bash "$SCRIPTS_DIR/cli/system_manage_docker.sh" --container_name="$container_name" --container_action="$container_action"
