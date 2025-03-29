#!/bin/bash

# ========================================
# ⚙️ setup-system.sh – Initialize WP Docker system
# ========================================

# Import config.sh
CONFIG_FILE="shared/config/config.sh"
while [ ! -f "$CONFIG_FILE" ]; do
    CONFIG_FILE="../$CONFIG_FILE"
    if [ "$(pwd)" = "/" ]; then
        echo "❌ Error: config.sh not found!" >&2
        exit 1
    fi
done

source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/wp_utils.sh"
source "$FUNCTIONS_DIR/php/php_get_version.sh"
source "$SCRIPTS_FUNCTIONS_DIR/website/website_check_and_up.sh"

# ✅ Set system timezone (if needed)
clear
setup_timezone

# ✅ Check Docker
if ! command -v docker &> /dev/null; then
    install_docker
else
    echo -e "${GREEN}✅ Docker is already installed.${NC}"
fi

# ✅ Check Docker Compose plugin
if ! docker compose version &> /dev/null; then
    install_docker_compose
else
    echo -e "${GREEN}✅ Docker Compose is already installed.${NC}"
fi

# ✅ Start Docker if not running
start_docker_if_needed

# ✅ Check docker group
check_docker_group

# ✅ Check shared/bin directory and install WP-CLI if not available
WP_CLI_PATH="$BASE_DIR/shared/bin/wp"
if [[ ! -f "$WP_CLI_PATH" ]]; then
    echo -e "${YELLOW}⚠️ WP-CLI is not installed. Installing WP-CLI...${NC}"
    
    # Download the latest WP-CLI from GitHub
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar || { echo "❌ Command failed at line 51"; exit 1; }

    # Grant execution permission and move to shared/bin directory
    chmod +x wp-cli.phar
    mv wp-cli.phar "$WP_CLI_PATH" || { echo "❌ Command failed at line 55"; exit 1; }

    echo -e "${GREEN}✅ WP-CLI has been successfully installed.${NC}"
else
    echo -e "${GREEN}✅ WP-CLI is already available at $WP_CLI_PATH.${NC}"
fi

# ✅ Start nginx-proxy and redis if not running
run_in_dir "$NGINX_PROXY_DIR" bash -c '
if ! docker compose ps | grep -q "nginx-proxy.*Up"; then
    echo -e "${YELLOW}🌀 nginx-proxy container is not running. Starting...${NC}"
    docker compose up -d || { echo "❌ Command failed at line 66"; exit 1; }
fi

# ⏳ Wait for nginx-proxy container to fully start
echo -e "${YELLOW}⏳ Checking nginx-proxy container status...${NC}"
for i in {1..10}; do
    status=$(docker inspect -f "{{.State.Status}}" nginx-proxy 2>/dev/null)
    if [[ "$status" == "running" ]]; then
        echo -e "${GREEN}✅ nginx-proxy container is running.${NC}"
        break
    fi
    sleep 1
done

if [[ "$status" != "running" ]]; then
    echo -e "${RED}❌ nginx-proxy container FAILED to start.${NC}"
    echo -e "${YELLOW}📋 Below is the most recent startup log of the container:${NC}\n"
    docker logs nginx-proxy 2>&1 | tail -n 30 || { echo "❌ Command failed at line 83"; exit 1; }
    echo -e "\n${RED}💥 Please check the configuration file, volume mount, or port usage.${NC}"
    exit 1
fi
'

# Check network & website, etc.
create_docker_network "$DOCKER_NETWORK"
website_check_and_up

# ✅ Fetch the latest PHP tags from Docker Hub
php_get_version

# ✅ Check required packages
check_required_commands
# ✅ Display configuration information
echo -e "${CYAN}📁 BASE_DIR: $BASE_DIR${NC}"
echo -e "${CYAN}📝 DEV_MODE: $DEV_MODE${NC}"
echo -e "${CYAN}📦 LOGS_DIR: $LOGS_DIR${NC}"

echo -e "\n${GREEN}✅ The system is ready to use WP Docker LEMP.${NC}"
