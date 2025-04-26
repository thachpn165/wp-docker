#!/bin/bash

# =====================================
# 🗑️ uninstall.sh – Completely remove WP Docker from the system
# =====================================

# === Load configuration from any directory ===
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

safe_source "$FUNCTIONS_DIR/website_loader.sh"

readonly MOVED_BACKUP_DIR="$HOME/archives"

# =====================================
# 🔐 Confirm uninstall prompt (for backup)
# =====================================
confirm_backup_before_remove() {
  confirm_text=$(get_input_or_test_value "$PROMPT_CONFIRM_UNINSTALL_BACKUP" "${TEST_CONFIRM_UNINSTALL_BACKUP:-n}")
  [[ "$confirm_text" =~ ^[Yy]$ ]]
}

# =====================================
# 🔐 Confirm remove MySQL container + volume
# =====================================
confirm_remove_mysql_volume() {
  local prompt="❓ Do you want to remove the MySQL container ($MYSQL_CONTAINER_NAME) and volume ($MYSQL_VOLUME_NAME)? (y/n) "
  local confirm_text
  confirm_text=$(get_input_or_test_value "$prompt" "n")
  [[ "$confirm_text" =~ ^[Yy]$ ]]
}

# =====================================
# 📦 Get list of all sites
# =====================================
get_site_list() {
  find "$SITES_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
}

# =====================================
# 💾 Backup all sites before deletion
# =====================================
backup_all_sites() {
  print_msg info "$(printf "$INFO_BACKUP_BEFORE_REMOVE" "$MOVED_BACKUP_DIR")"
  mkdir -p "$MOVED_BACKUP_DIR"

  for site in $(get_site_list); do
    print_msg info "$(printf "$INFO_SITE_BACKUP" "$site")"
    local site_path="$SITES_DIR/$site"
    local wordpress_dir="$site_path/wordpress"
    local backup_target_dir="$MOVED_BACKUP_DIR/$site"
    mkdir -p "$backup_target_dir"

    local db_name db_user db_pass
    db_name="$(json_get_site_value "$site" "db_name")"
    db_user="$(json_get_site_value "$site" "db_user")"
    db_pass="$(json_get_site_value "$site" "db_pass")"

    if [[ -z "$db_name" || -z "$db_user" || -z "$db_pass" ]]; then
      print_msg warning "$(printf "$ERROR_DB_INFO_MISSING" "$site")"
      continue
    fi

    local db_backup_file="$backup_target_dir/${site}_db.sql"
    run_cmd docker exec --env MYSQL_PWD="$db_pass" "$MYSQL_CONTAINER_NAME" \
      sh -c "exec mysqldump -u$db_user $db_name" true >"$db_backup_file" || {
      print_msg warning "$(printf "$ERROR_DB_BACKUP_FAILED" "$site")"
      continue
    }

    tar -czf "$backup_target_dir/${site}_wordpress.tar.gz" -C "$wordpress_dir" . || {
      print_msg warning "$(printf "$ERROR_SOURCE_BACKUP_FAILED" "$site")"
      continue
    }

    print_msg success "$(printf "$SUCCESS_SITE_BACKED_UP" "$site" "$backup_target_dir")"
  done
}

# =====================================
# 🧹 Remove core containers (NGINX, Redis)
# =====================================
remove_core_containers() {
  print_msg info "$INFO_REMOVING_CORE_CONTAINERS"
  docker rm -f "$NGINX_PROXY_CONTAINER" "$REDIS_CONTAINER" 2>/dev/null || true
}

# =====================================
# 🧨 Remove each site's containers (only PHP)
# =====================================
remove_site_containers() {
  if [[ ! -d "$SITES_DIR" ]]; then
    print_msg warning "⚠️ Directory $SITES_DIR does not exist. Skipping site container removal."
    return 0
  fi

  for site in $(get_site_list); do
    print_msg info "$(printf "$INFO_REMOVING_SITE_CONTAINERS" "$site")"
    docker rm -f "$site-php" 2>/dev/null || true
  done
}

# =====================================
# 🧨 Confirm and remove MySQL container + volume
# =====================================
remove_mysql_container_and_volume() {
  if confirm_remove_mysql_volume; then
    print_msg info "🧨 Removing MySQL container and volume..."
    docker rm -f "$MYSQL_CONTAINER_NAME" 2>/dev/null || true
    docker volume rm "$MYSQL_VOLUME_NAME" 2>/dev/null || true
  else
    print_msg warning "⚠️ Skipped removing MySQL container and volume."
  fi
}

# =====================================
# 🗑️ Remove all except backup folder
# =====================================
remove_all_except_backup() {
  print_msg info "$INFO_REMOVING_ALL_EXCEPT_BACKUP"
  for item in "$BASE_DIR"/*; do
    [[ "$item" == "$MOVED_BACKUP_DIR" ]] && continue
    [[ "$item" == "$BASE_DIR/.git" || "$item" == "$BASE_DIR/.github" ]] && continue

    if [[ -e "$item" ]]; then
      if [[ -f "$item" ]]; then
        remove_file "$item" || {
          print_and_debug error "$(printf "$ERROR_REMOVE_FAILED_LINE" "${LINENO}")"
          exit 1
        }
      elif [[ -d "$item" ]]; then
        remove_directory "$item" || {
          print_and_debug error "$(printf "$ERROR_REMOVE_FAILED_LINE" "${LINENO}")"
          exit 1
        }
      else
        debug_log "[remove_all_except_backup] Skipping: $item (not file or directory)"
      fi
    else
      debug_log "[remove_all_except_backup] Skipping non-existent: $item"
    fi
  done
}


# =====================================
# ⏰ Remove backup-related cronjobs
# =====================================
remove_cronjobs() {
  print_msg info "$INFO_REMOVING_CRONJOBS"
  crontab -l 2>/dev/null | grep -v "cron_loader.sh" | crontab - || true
}

# =====================================
# 📋 Show remaining Docker containers
# =====================================
show_remaining_containers() {
  print_msg info "$INFO_LIST_REMAINING_CONTAINERS"
  local remaining
  remaining=$(docker ps -a --format '{{.Names}}')
  if [[ -z "$remaining" ]]; then
    print_msg success "$SUCCESS_NO_CONTAINERS"
  else
    docker ps -a
    echo -e "\n${YELLOW}💡 $TIP_MANUAL_REMOVE_CONTAINERS${NC}"
    echo "$remaining" | while read -r name; do
      echo "docker stop $name && docker rm $name"
    done
  fi
}

# =====================================
# 🧹 Remove alias from shell config
# =====================================
remove_alias() {
  local shell_config
  if [[ "$SHELL" == *"zsh"* ]]; then
    shell_config="$HOME/.zshrc"
  else
    shell_config="$HOME/.bashrc"
  fi

  if grep -q "alias wpdocker=" "$shell_config"; then
    print_msg info "$(printf "$INFO_REMOVING_ALIAS" "$shell_config")"
    sedi "/alias wpdocker=/d" "$shell_config"
  else
    print_msg warning "$(printf "$WARNING_ALIAS_NOT_FOUND" "$shell_config")"
  fi
}

# =====================================
# 🚀 MAIN: Start Uninstall Process
# =====================================
print_msg warning "$WARNING_UNINSTALL_CONFIRM"
print_msg info "$INFO_UNINSTALL_NOTICE"

if confirm_backup_before_remove; then
  backup_all_sites
else
  print_msg info "$INFO_SKIP_BACKUP"
fi

remove_core_containers
remove_site_containers
remove_mysql_container_and_volume
remove_cronjobs
remove_all_except_backup
remove_alias
core_system_uninstall_required_commands
print_msg success "$(printf "$SUCCESS_SYSTEM_UNINSTALLED" "$MOVED_BACKUP_DIR")"
print_msg info "$(printf "$INFO_RESTORE_INSTRUCTION" "$MOVED_BACKUP_DIR")"
rm -rf "$INSTALL_DIR"
