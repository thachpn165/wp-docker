#!/bin/bash
# === Load config & wordpress_loader.sh ===
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
source "$FUNCTIONS_DIR/wordpress_loader.sh"

echo -e "${CYAN}🌐 WordPress Migration Tool${NC}"
echo ""

# Inform the user about the migration process
echo -e "${YELLOW} ${WARNING} Please prepare your migration source files before continuing:${NC}"
echo -e "  - Create a folder named after your domain at: ${BLUE}$INSTALL_DIR/archives/domain.ltd (replace domain.ltd with your domain) ${NC}"
echo -e "  - Inside that folder, place:"
echo -e "     - A .zip or .tar.gz file containing your website source code"
echo -e "     - A .sql file containing the database export"
echo ""

read -rp "Have you prepared the archive folder and files correctly? (y/n): " ready
if [[ "$ready" != "y" && "$ready" != "Y" ]]; then
  echo -e "${RED}${CROSSMARK} Migration canceled. Please prepare the necessary files first.${NC}"
  exit 1
fi

echo ""
read -rp "👉 Enter domain name to migrate (must match folder name in 'archives/'): " domain
if [[ -z "$domain" ]]; then
  echo -e "${RED}${CROSSMARK} Domain is required.${NC}"
  exit 1
fi

echo ""
echo -e "${YELLOW}⚙️ Starting migration process for '${domain}'...${NC}"
bash "$CLI_DIR/wordpress_migration.sh" --domain="$domain"