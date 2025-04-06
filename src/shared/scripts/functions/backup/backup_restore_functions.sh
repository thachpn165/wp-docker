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
  DB_CONTAINER="$2"       # Name of container containing database (mariadb)
  SITE_DOMAIN="$3"          # Website name to find .env and other details
  local formatted_msg_restoring_database
  formatted_msg_restoring_database="$(printf "$MSG_BACKUP_RESTORING_DB" "$DB_BACKUP" "$DB_CONTAINER")"
  if [[ -z "$DB_BACKUP" || -z "$DB_CONTAINER" || -z "$domain" ]]; then
    #echo "${CROSSMARK} Missing parameters: Invalid database backup file path, container, or site name!"
    print_and_debug error "$ERROR_BACKUP_RESTORE_DB_MISSING_PARAMS"
    debug_log "[Debug] Failed Database backup file: $DB_BACKUP"
    debug_log "[Debug] Failed Database container: $DB_CONTAINER"
    debug_log "[Debug] Failed Site domain: $SITE_DOMAIN"
    return 1
  fi

  # Get database name from .env file
  DB_NAME=$(fetch_env_variable "$SITES_DIR/$domain/.env" "MYSQL_DATABASE")
  
  if [[ -z "$DB_NAME" ]]; then
    #echo "${CROSSMARK} Could not get database name from .env"
    print_and_debug error "$ERROR_BACKUP_FAILED_FETCH_DB_NAME_ENV"
    debug_log "[Debug] Failed Database name: $DB_NAME"
    return 1
  fi

  # Check if database backup file exists
  if [[ ! -f "$DB_BACKUP" ]]; then
    #echo "${CROSSMARK} Database backup file not found: $DB_BACKUP"
    print_and_debug error "$MSG_NOT_FOUND: $DB_BACKUP"
    debug_log "[Debug] Failed Database backup file: $DB_BACKUP"
    return 1
  fi

  # Get MYSQL_ROOT_PASSWORD from .env
  MYSQL_ROOT_PASSWORD=$(fetch_env_variable "$SITES_DIR/$domain/.env" "MYSQL_ROOT_PASSWORD")
  
  if [[ -z "$MYSQL_ROOT_PASSWORD" ]]; then
    #echo "${CROSSMARK} Missing MySQL root password. Cannot restore database."
    print_and_debug error "$ERROR_BACKUP_PASSWD_NOT_FOUND"
    debug_log "[Debug] Failed MySQL root password: $MYSQL_ROOT_PASSWORD"
    # check .env file
    if [[ ! -f "$SITES_DIR/$domain/.env" ]]; then
      print_and_debug error "$ERROR_BACKUP_ENV_FILE_NOT_FOUND $SITES_DIR/$domain/.env"
      debug_log "[Debug] Failed .env file: $SITES_DIR/$domain/.env"
    fi
    return 1
  fi

  # Restore database from backup file
  print_and_debug step "$formatted_msg_restoring_database"
  # Drop database if exists and create new one
  docker exec -e MYSQL_PWD="$MYSQL_ROOT_PASSWORD" -i "$DB_CONTAINER" mysql -u root -e "DROP DATABASE IF EXISTS $DB_NAME; CREATE DATABASE $DB_NAME;"

  # Restore database
  docker exec -e MYSQL_PWD="$MYSQL_ROOT_PASSWORD" -i "$DB_CONTAINER" mysql -u root "$DB_NAME" < "$DB_BACKUP"

  if [[ $? -eq 0 ]]; then
    #echo "${CHECKMARK} Database has been successfully restored from backup to database '$DB_NAME'."
    print_and_debug success "$SUCCESS_BACKUP_RESTORED_DB $DB_NAME"
  else
    #echo "${CROSSMARK} An error occurred while restoring database from backup."
    print_and_debug error "$ERROR_BACKUP_RESTORE_DB_FAILED"
    debug_log "[Debug] Failed Database restore: $DB_BACKUP"
    debug_log "[Debug] Failed Database name: $DB_NAME"
    debug_log "[Debug] Failed Database container: $DB_CONTAINER"
    return 1
  fi
}
