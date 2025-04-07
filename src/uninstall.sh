#!/bin/bash

# =====================================
# ${CROSSMARK} uninstall.sh – Completely remove WP Docker from the system
# =====================================
# ✅ Load configuration from any directory
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
SEARCH_PATH="$SCRIPT_PATH"
while [[ "$SEARCH_PATH" != "/" ]]; do
  if [[ -f "$SEARCH_PATH/shared/config/load_config.sh" ]]; then
    source "$SEARCH_PATH/shared/config/load_config.sh"
    load_config_file
    break
  fi
  SEARCH_PATH="$(dirname "$SEARCH_PATH")"
done

# Load functions for website management
source "$FUNCTIONS_DIR/website_loader.sh"

BACKUP_DIR="$BASE_DIR/archives/backups_before_remove"
TMP_BACKUP_DIR="$BASE_DIR/tmp"

# 💬 Confirm action from user
confirm_action() {
  read -rp "❓ Do you want to backup all websites before deletion? [y/N]: " confirm
  [[ "$confirm" == "y" || "$confirm" == "Y" ]]
}

# 🔍 Scan site list from sites directory
get_site_list() {
  find "$SITES_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
}

# ${SAVE} Manually backup all sites to backup_before_remove
backup_all_sites() {
  echo -e "${CYAN}${SAVE} Backing up all sites to $BACKUP_DIR...${NC}"
  mkdir -p "$BACKUP_DIR"

  for site in $(get_site_list); do
    echo -e "${BLUE}📦 Backing up site: $site${NC}"

    site_path="$SITES_DIR/$site"
    env_file="$site_path/.env"
    wordpress_dir="$site_path/wordpress"
    backup_target_dir="$BACKUP_DIR/$site"
    mkdir -p "$backup_target_dir"

    if [[ ! -f "$env_file" ]]; then
      echo -e "${RED}${CROSSMARK} Skipping site '$site': .env file not found${NC}"
      continue
    fi

    # Get DB information from .env file
    DB_NAME=$(grep '^MYSQL_DATABASE=' "$env_file" | cut -d '=' -f2)
    DB_USER=$(grep '^MYSQL_USER=' "$env_file" | cut -d '=' -f2)
    DB_PASS=$(grep '^MYSQL_PASSWORD=' "$env_file" | cut -d '=' -f2)
    # fallback to prompt if not found
    if [ -z "$DB_PASS" ]; then
        echo "🔐 Database password not found in $env_file"
        read -s -p "Please enter database password: " DB_PASS
        echo ""
    fi
    if [[ -z "$DB_NAME" || -z "$DB_USER" || -z "$DB_PASS" ]]; then
      echo -e "${RED}${CROSSMARK} Unable to get database information from .env, skipping site '$site'${NC}"
      continue
    fi

    # Backup database
    db_backup_file="$backup_target_dir/${site}_db.sql"
    echo -e "${YELLOW}📦 Backing up database: $DB_NAME${NC}"
    docker exec "${site}-mariadb" sh -c "exec mysqldump -u$DB_USER -p\"$DB_PASS\" $DB_NAME" > "$db_backup_file" || {
      echo -e "${RED}${CROSSMARK} Error backing up database for site '$site'${NC}"
      continue
    }

    # Backup source code
    echo -e "${YELLOW}📦 Compressing WordPress source code...${NC}"
    tar -czf "$backup_target_dir/${site}_wordpress.tar.gz" -C "$wordpress_dir" . || {
      echo -e "${RED}${CROSSMARK} Error compressing source code for site '$site'${NC}"
      continue
    }

    echo -e "${GREEN}${CHECKMARK} Backup completed for site '$site' at: $backup_target_dir${NC}"
  done
}

# 🧹 Remove core containers
remove_core_containers() {
  echo -e "${YELLOW}🧹 Removing core containers: nginx-proxy and redis-cache...${NC}"
  docker rm -f "$NGINX_PROXY_CONTAINER" redis-cache 2>/dev/null || true
}

# 🧹 Remove all containers and volumes related to each site
remove_site_containers() {
  for site in $(get_site_list); do
    echo -e "${YELLOW}🧨 Removing containers for site: $site${NC}"
    docker rm -f "$site-php" "$site-mariadb" 2>/dev/null || true
    docker volume rm "${site}_db_data" 2>/dev/null || true
  done
}

# 🧨 Remove all directories except backup
remove_all_except_backup() {
  echo -e "${MAGENTA}🗑️  Removing entire system except backup_before_remove directory...${NC}"
  for item in "$BASE_DIR"/*; do
    [[ "$item" == "$BACKUP_DIR" ]] && continue
    [[ "$item" == "$BASE_DIR/.git" || "$item" == "$BASE_DIR/.github" ]] && continue
    if [[ -e "$item" ]]; then
        remove_file "$item" || { echo "${CROSSMARK} Command failed at line 104"; exit 1; }
      else
        debug_log "[remove_all_except_backup] Skipping non-existent item: $item"
      fi
    done
  done
}

# 🗑️ Remove wpdocker command symlink if exists
remove_symlink() {
  if [ -L "/usr/local/bin/wpdocker" ]; then
    echo -e "${YELLOW}🗑️ Removing symlink /usr/local/bin/wpdocker...${NC}"
    rm -f /usr/local/bin/wpdocker
  fi
}

# 🧽 Remove backup-related cronjobs
remove_cronjobs() {
  echo -e "${YELLOW}🧽 Removing backup cronjobs (if any)...${NC}"
  crontab -l 2>/dev/null | grep -v "backup_runner.sh" | crontab - || true
}

# 🧾 Display remaining containers after removal
show_remaining_containers() {
  echo -e "\n${CYAN}📋 List of remaining containers after uninstallation:${NC}"
  remaining=$(docker ps -a --format '{{.Names}}')
  if [[ -z "$remaining" ]]; then
    echo -e "${GREEN}${CHECKMARK} No Docker containers remaining.${NC}"
  else
    docker ps -a || { echo "${CROSSMARK} Command failed at line 129"; exit 1; }
    echo -e "\n${YELLOW}💡 If you want to remove all remaining containers, run these commands:${NC}"
    echo "$remaining" | while read -r name; do
      echo "docker stop $name && docker rm $name"
    done
  fi
}

# 🧹 Remove alias for wpdocker in .bashrc or .zshrc if exists
remove_alias() {
  local shell_config
  local alias_line="alias wpdocker=\"bash \$CLI_DIR/wp-docker-lemp/bin/wp-docker\""

  # Check if using Zsh or Bash
  if [[ "$SHELL" == *"zsh"* ]]; then
    shell_config="$HOME/.zshrc"
  else
    shell_config="$HOME/.bashrc"
  fi

  # Check if the alias is present and remove it
  if grep -q "$alias_line" "$shell_config"; then
    echo "${CHECKMARK} Removing alias for wpdocker from $shell_config..."
    sed -i "/$alias_line/d" "$shell_config"
  else
    echo "${WARNING} Alias 'wpdocker' not found in $shell_config"
  fi
}

# ================================
# 🚀 Main Process
# ================================

echo -e "${RED}${WARNING} WARNING: This script will remove the entire WP Docker system!${NC}"
echo "Including all sites, containers, volumes, source code, SSL, and configurations."

if confirm_action; then
  backup_all_sites
else
  echo -e "${YELLOW}⏩ Skipping backup step.${NC}"
fi

remove_core_containers
remove_site_containers
remove_cronjobs
remove_symlink
remove_all_except_backup

echo -e "\n${GREEN}${CHECKMARK} System completely uninstalled. Backup (if any) is located in: $BACKUP_DIR${NC}"
echo -e "${CYAN}📦 You can restore sites from the backup directory: $BACKUP_DIR${NC}"
echo -e "${CYAN}👉 Use the 'Restore website from backup' menu after reinstallation to restore.${NC}"
remove_alias
show_remaining_containers
