safe_source "$CLI_DIR/database_actions.sh"
# ===========================================
# 📦 backup_restore_files – Restore website source code from .tar.gz backup
# ===========================================
# Parameters:
#   $1 - Path to source code backup file (.tar.gz)
#   $2 - Site directory where files should be restored
# ===========================================
backup_restore_files() {
  local backup_file="$1"
  local site_dir="$2"

  # === Validate parameters ===
  if [[ -z "$backup_file" || -z "$site_dir" ]]; then
    print_and_debug error "$ERROR_BACKUP_RESTORE_FILE_MISSING_PARAMS"
    debug_log "[Debug] Missing BACKUP_FILE: $backup_file"
    debug_log "[Debug] Missing SITE_DIR: $site_dir"
    return 1
  fi

  # === Check if file exists ===
  if [[ ! -f "$backup_file" ]]; then
    print_and_debug error "$MSG_NOT_FOUND: $backup_file"
    return 1
  fi

  # Confirm before overwriting
  if ! confirm_action "$(printf "$QUESTION_BACKUP_RESTORE_CONFIRM" "${YELLOW}$site_dir${NC}")"; then
    print_and_debug cancel "$MSG_OPERATION_CANCELLED"
    return 0
  fi
  local msg_restore
  msg_restore="$(printf "$MSG_BACKUP_RESTORING_FILE" "$backup_file" "$site_dir")"
  print_msg step "$msg_restore"

  # === Extract to wordpress directory ===
  # Using tar for tar.fz file
  # Using unzip for zip file
  case "$backup_file" in
  *.zip)
    unzip -o "$backup_file" -d "$site_dir/wordpress"
    debug_log "[Debug] Unzipped file: $backup_file"
    ;;
  *.tar.gz)
    tar -xzf "$backup_file" -C "$site_dir/wordpress"
    debug_log "[Debug] Extract with tar: $backup_file"
    ;;
  *.gz)
    gunzip -c "$backup_file" >"${backup_file%.gz}" && mv "${backup_file%.gz}" "$site_dir/wordpress"
    debug_log "[Debug] Extract with gunzip: $backup_file"
    ;;
  *)
    print_msg error "❌ Unsupported backup file format: $backup_file"
    return 1
    ;;
  esac

  if [[ $? -eq 0 ]]; then
    print_msg success "$SUCCESS_BACKUP_RESTORED_FILE"
  else
    print_and_debug error "$ERROR_BACKUP_RESTORE_FAILED"
    return 1
  fi
}
# ===========================================
# 🧠 backup_restore_database – Restore MySQL database from .sql backup
# ===========================================
# Parameters:
#   $1 - Path to database backup file (.sql)
#   $2 - Site domain (used to fetch DB credentials)
# ===========================================
backup_restore_database() {
  local db_backup="$1"
  local site_domain="$2"

  # === Validate parameters ===
  if [[ -z "$db_backup" || -z "$site_domain" ]]; then
    print_and_debug error "$ERROR_BACKUP_RESTORE_DB_MISSING_PARAMS"
    debug_log "[Debug] Missing DB_BACKUP: $db_backup"
    debug_log "[Debug] Missing SITE_DOMAIN: $site_domain"
    return 1
  fi
  # === Check if file exists ===
  if [[ ! -f "$db_backup" ]]; then
    print_and_debug error "$MSG_NOT_FOUND: $db_backup"
    return 1
  fi

  # === Confirm before overwriting ===
  if ! confirm_action "$(printf "$QUESTION_BACKUP_RESTORE_DB_CONFIRM" "${YELLOW}$site_domain${NC}")"; then
    print_and_debug cancel "$MSG_OPERATION_CANCELLED"
    return 0
  fi

  local msg_restore
  msg_restore="$(printf "$MSG_BACKUP_RESTORING_DB" "$db_backup" "$site_domain")"
  print_and_debug step "$msg_restore"

  # === Delegate to database import CLI ===
  debug_log "[Debug] Importing database using: database_import.sh --domain=$site_domain"
  database_cli_import \
    --domain="$site_domain" \
    --backup_file="$db_backup" || {
    print_and_debug error "$ERROR_BACKUP_RESTORE_DB_FAILED"
    return 1
  }
}
