#!/bin/bash

# ===========================================
# Function to restore website source code backup
# ===========================================

backup_restore_files() {
  BACKUP_FILE="$1"  # Path to source code backup file (tar.gz)
  SITE_DIR="$2"     # Directory containing website to restore
  local formatted_msg_restoring_source_code
  formatted_msg_restoring_source_code="$(printf "$MSG_BACKUP_RESTORING_FILE" "$BACKUP_FILE" "$SITE_DIR")"

  
  if [[ -z "$BACKUP_FILE" || -z "$SITE_DIR" ]]; then
    print_and_debug error "$ERROR_BACKUP_RESTORE_FILE_MISSING_PARAMS"
    debug_log "[Debug] Failed Backup file: $BACKUP_FILE"
    debug_log "[Debug] Failed Site directory: $SITE_DIR"
    return 1
  fi

  # Check if backup file exists
  if [[ ! -f "$BACKUP_FILE" ]]; then
    print_and_debug error "$MSG_NOT_FOUND: $BACKUP_FILE"
    return 1
  fi

  # Extract source code to website directory
  print_and_debug step "$formatted_msg_restoring_source_code"
  tar -xzf "$BACKUP_FILE" -C "$SITE_DIR/wordpress"
  if [[ $? -eq 0 ]]; then
    print_and_debug success "$SUCCESS_BACKUP_RESTORED_FILE"
  else
    print_and_debug error "$ERROR_BACKUP_RESTORE_FAILED"
    return 1
  fi
}

# ===========================================
# Function to restore database backup
# ===========================================

backup_restore_database() {
  DB_BACKUP="$1"          # Path to database backup file (.sql)
  SITE_DOMAIN="$2"        # Website name to find .env and other details

  local formatted_msg_restoring_database
  formatted_msg_restoring_database="$(printf "$MSG_BACKUP_RESTORING_DB" "$DB_BACKUP" "$SITE_DOMAIN")"

  if [[ -z "$DB_BACKUP" || -z "$SITE_DOMAIN" ]]; then
    print_and_debug error "$ERROR_BACKUP_RESTORE_DB_MISSING_PARAMS"
    debug_log "[Debug] Failed Database backup file: $DB_BACKUP"
    debug_log "[Debug] Failed Site domain: $SITE_DOMAIN"
    return 1
  fi

  if [[ ! -f "$DB_BACKUP" ]]; then
    print_and_debug error "$MSG_NOT_FOUND: $DB_BACKUP"
    debug_log "[Debug] Failed Database backup file: $DB_BACKUP"
    return 1
  fi

  print_and_debug step "$formatted_msg_restoring_database"
  debug_log "[Debug] Delegating database restore to: cli/website_database_import.sh --domain=\"$SITE_DOMAIN\" --backup_file=\"$DB_BACKUP\""

  bash "$CLI_DIR/database_import.sh" \
    --domain="$SITE_DOMAIN" \
    --backup_file="$DB_BACKUP" || {
      print_and_debug error "$ERROR_BACKUP_RESTORE_DB_FAILED"
      return 1
    }
}
