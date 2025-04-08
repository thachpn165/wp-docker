#!/bin/bash

# =====================================
# 🗑️ uninstall.sh – Completely remove WP Docker from the system
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

source "$FUNCTIONS_DIR/website_loader.sh"

readonly BACKUP_DIR="$BASE_DIR/archives/backups_before_remove"
readonly TMP_BACKUP_DIR="$BASE_DIR/tmp"

# 🟡 Prompt confirmation
confirm_action() {
  confirm_text=$(get_input_or_test_value "$PROMPT_CONFIRM_UNINSTALL_BACKUP" "${TEST_CONFIRM_UNINSTALL_BACKUP:-n}")
  [[ "$confirm_text" =~ ^[Yy]$ ]]
}

# 🔍 Lấy danh sách site
get_site_list() {
  find "$SITES_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
}

# 💾 Backup toàn bộ site nếu cần
backup_all_sites() {
  print_msg info "$(printf "$INFO_BACKUP_BEFORE_REMOVE" "$BACKUP_DIR")"
  mkdir -p "$BACKUP_DIR"

  for site in $(get_site_list); do
    print_msg info "$(printf "$INFO_SITE_BACKUP" "$site")"

    local site_path="$SITES_DIR/$site"
    local env_file="$site_path/.env"
    local wordpress_dir="$site_path/wordpress"
    local backup_target_dir="$BACKUP_DIR/$site"
    mkdir -p "$backup_target_dir"

    if [[ ! -f "$env_file" ]]; then
      print_msg warning "$(printf "$WARNING_ENV_FILE_NOT_FOUND" "$site")"
      continue
    fi

    local db_info
    db_info=$(db_fetch_env "$site")
    if [[ $? -ne 0 ]]; then
      print_msg warning "$(printf "$ERROR_DB_INFO_MISSING" "$site")"
      continue
    fi
    IFS=' ' read -r DB_NAME DB_USER DB_PASS <<< "$db_info"

    local db_backup_file="$backup_target_dir/${site}_db.sql"
    run_cmd "docker exec ${site}-mariadb sh -c 'exec mysqldump -u$DB_USER -p\"$DB_PASS\" $DB_NAME'" true > "$db_backup_file" || {
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

# 🧹 Xoá core container
remove_core_containers() {
  print_msg info "$INFO_REMOVING_CORE_CONTAINERS"
  docker rm -f "$NGINX_PROXY_CONTAINER" redis-cache 2>/dev/null || true
}

# 🧨 Xoá container, volume của từng site
remove_site_containers() {
  for site in $(get_site_list); do
    print_msg info "$(printf "$INFO_REMOVING_SITE_CONTAINERS" "$site")"
    docker rm -f "$site-php" "$site-mariadb" 2>/dev/null || true
    docker volume rm "${site}_db_data" 2>/dev/null || true
  done
}

# 🗑️ Xoá tất cả trừ thư mục backup
remove_all_except_backup() {
  print_msg info "$INFO_REMOVING_ALL_EXCEPT_BACKUP"
  for item in "$BASE_DIR"/*; do
    [[ "$item" == "$BACKUP_DIR" ]] && continue
    [[ "$item" == "$BASE_DIR/.git" || "$item" == "$BASE_DIR/.github" ]] && continue
    if [[ -e "$item" ]]; then
      remove_file "$item" || {
        print_and_debug error "$(printf "$ERROR_REMOVE_FAILED_LINE" 104)"
        exit 1
      }
    else
      debug_log "[remove_all_except_backup] Skipping non-existent: $item"
    fi
  done
}

# 🔗 Xoá symlink wpdocker nếu tồn tại
remove_symlink() {
  if [[ -L "/usr/local/bin/wpdocker" ]]; then
    print_msg info "$INFO_REMOVING_SYMLINK"
    rm -f /usr/local/bin/wpdocker
  fi
}

# 🧽 Xoá cronjob liên quan đến backup
remove_cronjobs() {
  print_msg info "$INFO_REMOVING_CRONJOBS"
  crontab -l 2>/dev/null | grep -v "backup_runner.sh" | crontab - || true
}

# 🧾 Hiển thị container còn lại
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

# 🧹 Xoá alias trong file shell config
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

# 🚀 Main
print_msg warning "$WARNING_UNINSTALL_CONFIRM"
print_msg info "$INFO_UNINSTALL_NOTICE"

if confirm_action; then
  backup_all_sites
else
  print_msg info "$INFO_SKIP_BACKUP"
fi

remove_core_containers
remove_site_containers
remove_cronjobs
remove_symlink
remove_all_except_backup
remove_alias

print_msg success "$(printf "$SUCCESS_SYSTEM_UNINSTALLED" "$BACKUP_DIR")"
print_msg info "$(printf "$INFO_RESTORE_INSTRUCTION" "$BACKUP_DIR")"

show_remaining_containers