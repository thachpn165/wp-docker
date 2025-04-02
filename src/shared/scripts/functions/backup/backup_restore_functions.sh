#!/bin/bash

# ===========================================
# Function to restore website source code backup
# ===========================================

backup_restore_files() {
  BACKUP_FILE="$1"  # Path to source code backup file (tar.gz)
  SITE_DIR="$2"     # Directory containing website to restore

  if [[ -z "$BACKUP_FILE" || -z "$SITE_DIR" ]]; then
    echo "${CROSSMARK} Missing parameters: Invalid backup file path or website directory!"
    return 1
  fi

  # Check if backup file exists
  if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "${CROSSMARK} Backup file not found: $BACKUP_FILE"
    return 1
  fi

  # Extract source code to website directory
  echo "📦 Restoring source code from $BACKUP_FILE to $SITE_DIR/wordpress..."
  tar -xzf "$BACKUP_FILE" -C "$SITE_DIR/wordpress"
  
  if [[ $? -eq 0 ]]; then
    echo "${CHECKMARK} Source code has been successfully restored from backup."
  else
    echo "${CROSSMARK} An error occurred while restoring source code from backup."
    return 1
  fi
}

# ===========================================
# Function to restore database backup
# ===========================================

backup_restore_database() {
  DB_BACKUP="$1"          # Path to database backup file (.sql)
  DB_CONTAINER="$2"       # Name of container containing database (mariadb)
  SITE_NAME="$3"          # Website name to find .env and other details

  if [[ -z "$DB_BACKUP" || -z "$DB_CONTAINER" || -z "$SITE_NAME" ]]; then
    echo "${CROSSMARK} Missing parameters: Invalid database backup file path, container, or site name!"
    return 1
  fi

  # Get database name from .env file
  DB_NAME=$(fetch_env_variable "$SITES_DIR/$SITE_NAME/.env" "MYSQL_DATABASE")
  
  if [[ -z "$DB_NAME" ]]; then
    echo "${CROSSMARK} Could not get database name from .env"
    return 1
  fi

  # Check if database backup file exists
  if [[ ! -f "$DB_BACKUP" ]]; then
    echo "${CROSSMARK} Database backup file not found: $DB_BACKUP"
    return 1
  fi

  # Get MYSQL_ROOT_PASSWORD from .env
  MYSQL_ROOT_PASSWORD=$(fetch_env_variable "$SITES_DIR/$SITE_NAME/.env" "MYSQL_ROOT_PASSWORD")
  
  if [[ -z "$MYSQL_ROOT_PASSWORD" ]]; then
    echo "${CROSSMARK} Missing MySQL root password. Cannot restore database."
    return 1
  fi

  # Restore database from backup file
  echo "🔄 Restoring database from $DB_BACKUP to container $DB_CONTAINER..."

  # Drop database if exists and create new one
  docker exec -i "$DB_CONTAINER" mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "DROP DATABASE IF EXISTS $DB_NAME; CREATE DATABASE $DB_NAME;"

  # Restore database
  docker exec -i "$DB_CONTAINER" mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$DB_NAME" < "$DB_BACKUP"

  if [[ $? -eq 0 ]]; then
    echo "${CHECKMARK} Database has been successfully restored from backup to database '$DB_NAME'."
  else
    echo "${CROSSMARK} An error occurred while restoring database from backup."
    return 1
  fi
}


