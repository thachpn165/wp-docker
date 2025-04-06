#!/bin/bash

# ========================================
# ⚙️ setup-system.sh – Initialize WP Docker system
# ========================================

# === Load config.sh from anywhere using universal loader ===
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
while [[ "$SCRIPT_PATH" != "/" ]]; do
  if [[ -f "$SCRIPT_PATH/shared/config/load_config.sh" ]]; then
    source "$SCRIPT_PATH/shared/config/load_config.sh"
    break
  fi
  SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
done
source "$FUNCTIONS_DIR/utils/wp_utils.sh"
source "$FUNCTIONS_DIR/website/website_check_and_up.sh"
source "$FUNCTIONS_DIR/setup-aliases.sh"
source "$FUNCTIONS_DIR/utils/env_utils.sh"

# === Ensure CORE_CHANNEL is set in .env ===
if [[ ! -f "$CORE_ENV" ]]; then
  echo -e "${YELLOW}${WARNING} .env file not found. Creating new .env at $CORE_ENV${NC}"
  touch "$CORE_ENV"
fi

if ! grep -q "^CORE_CHANNEL=" "$CORE_ENV"; then
  echo -e "${CYAN}🌐 Please choose a release channel to use:${NC}"
  PS3="Choose channel: "
  select opt in "official" "nightly"; do
    case $opt in
      official|nightly)
        env_set_value "CORE_CHANNEL" "$opt"
        echo -e "${GREEN}${CHECKMARK} CORE_CHANNEL has been set to '$opt' in $CORE_ENV.${NC}"
        break
        ;;
      *)
        echo -e "${RED}${CROSSMARK} Invalid option. Please choose again.${NC}"
        ;;
    esac
  done
fi

# ${CHECKMARK} Set system timezone (if needed)
clear
setup_timezone
check_and_add_alias
# ${CHECKMARK} Check Docker
if ! command -v docker &> /dev/null; then
    install_docker
else
    echo -e "${GREEN}${CHECKMARK} Docker is already installed.${NC}"
fi

# ${CHECKMARK} Check Docker Compose plugin
if ! docker compose version &> /dev/null; then
    install_docker_compose
else
    echo -e "${GREEN}${CHECKMARK} Docker Compose is already installed.${NC}"
fi

# Check if php_get_version is already scheduled in crontab
if ! crontab -l | grep -q "$CLI_DIR/php_get_version.sh"; then
  # Add the cron job to run php_get_version.sh every day at 2am
  echo "0 2 * * * bash $CLI_DIR/php_get_version.sh" | crontab -
  echo -e "${GREEN}${CHECKMARK} Cron job has been added to run php_get_version.sh daily at 2am.${NC}"
else
  echo -e "${YELLOW}${WARNING} Cron job for php_get_version.sh already exists.${NC}"
fi

# ${CHECKMARK} Start Docker if not running
start_docker_if_needed

# ${CHECKMARK} Check docker group
check_docker_group

# ${CHECKMARK} Check shared/bin directory and install WP-CLI if not available
WP_CLI_PATH="$BASE_DIR/shared/bin/wp"
if [[ ! -f "$WP_CLI_PATH" ]]; then
    echo -e "${YELLOW}${WARNING} WP-CLI is not installed. Installing WP-CLI...${NC}"
    
    # Download the latest WP-CLI from GitHub
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar || { echo "${CROSSMARK} Command failed at line 51"; exit 1; }

    # Grant execution permission and move to shared/bin directory
    chmod +x wp-cli.phar
    mv wp-cli.phar "$WP_CLI_PATH" || { echo "${CROSSMARK} Command failed at line 55"; exit 1; }

    echo -e "${GREEN}${CHECKMARK} WP-CLI has been successfully installed.${NC}"
else
    echo -e "${GREEN}${CHECKMARK} WP-CLI is already available at $WP_CLI_PATH.${NC}"
fi

# ${CHECKMARK} Start nginx-proxy and redis if not running
pushd "$NGINX_PROXY_DIR" > /dev/null

if ! docker compose ps | grep -q "nginx-proxy.*Up"; then
    echo -e "${YELLOW}🌀 nginx-proxy container is not running. Starting...${NC}"
    docker compose up -d || { echo "${CROSSMARK} Command failed at line 66"; exit 1; }
fi

# ⏳ Wait for nginx-proxy container to fully start
echo -e "${YELLOW}⏳ Checking nginx-proxy container status...${NC}"
for i in {1..10}; do
    status=$(docker inspect -f "{{.State.Status}}" nginx-proxy 2>/dev/null)
    if [[ "$status" == "running" ]]; then
        echo -e "${GREEN}${CHECKMARK} nginx-proxy container is running.${NC}"
        break
    fi
    sleep 1
done

if [[ "$status" != "running" ]]; then
    echo -e "${RED}${CROSSMARK} nginx-proxy container FAILED to start.${NC}"
    echo -e "${YELLOW}📋 Below is the most recent startup log of the container:${NC}\n"
    docker logs nginx-proxy 2>&1 | tail -n 30 || { echo "${CROSSMARK} Command failed at line 83"; exit 1; }
    echo -e "\n${RED}💥 Please check the configuration file, volume mount, or port usage.${NC}"
    exit 1
fi

popd > /dev/null

# Check network & website, etc.
create_docker_network "$DOCKER_NETWORK"
website_check_and_up

# ${CHECKMARK} Check required packages
check_required_commands
# ${CHECKMARK} Display configuration information
echo -e "${CYAN}📁 BASE_DIR: $BASE_DIR${NC}"
echo -e "${CYAN}📦 LOGS_DIR: $LOGS_DIR${NC}"

echo -e "\n${GREEN}${CHECKMARK} The system is ready to use WP Docker LEMP.${NC}"
