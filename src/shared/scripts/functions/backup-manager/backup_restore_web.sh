#!/bin/bash

# =====================================
# 🔄 Restore website from backup (source code + database)
# =====================================

source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/backup_restore_functions.sh"

backup_restore_web() {
  echo -e "${BLUE}===== RESTORE WEBSITE FROM BACKUP =====${NC}"

  # ✅ Select website
  select_website || return 1
  echo "DEBUG: SITE_NAME=$SITE_NAME"  # Debugging line
  SITE_DIR="$SITES_DIR/$SITE_NAME"
  DB_CONTAINER="${SITE_NAME}-mariadb"

  if ! is_directory_exist "$SITE_DIR"; then
    echo -e "${RED}❌ Website directory does not exist: $SITE_DIR${NC}"
    return 1
  fi

  # ========== ♻ Restore Source Code ==========
  [[ "$TEST_MODE" != true ]] && read -p "📦 Do you want to restore SOURCE CODE? [y/N]: " confirm_code
  confirm_code=$(echo "$confirm_code" | tr '[:upper:]' '[:lower:]')
  if [[ "$confirm_code" == "y" ]]; then
    echo -e "\n📄 List of source code backup files (.tar.gz):"

    find "$SITE_DIR/backups" -type f -name "*.tar.gz" | while read file; do
    file_time=$(stat -f "%Sm" -t "%d-%m-%Y %H:%M:%S" "$file")
    file_name=$(basename "$file")
    echo -e "$file_name\t$file_time"
    done | nl -s ". "

    [[ "$TEST_MODE" != true ]] && read -p "📝 Enter source code backup filename or paste path: " CODE_BACKUP_FILE

    # Check if filename has relative path, convert to absolute path
    if [[ ! "$CODE_BACKUP_FILE" =~ ^/ ]]; then
        CODE_BACKUP_FILE="$SITE_DIR/backups/$CODE_BACKUP_FILE"
    fi

    # Check if file exists
    if [[ ! -f "$CODE_BACKUP_FILE" ]]; then
        echo "❌ Source code backup file does not exist: $CODE_BACKUP_FILE"
        exit 1
    else
        echo "✅ Found backup file: $CODE_BACKUP_FILE"
    fi

    backup_restore_files "$CODE_BACKUP_FILE" "$SITE_DIR"
  fi

  # ========== 🔄 Restore Database ==========
  [[ "$TEST_MODE" != true ]] && read -p "🛢  Do you want to restore DATABASE? [y/N]: " confirm_db
  confirm_db=$(echo "$confirm_db" | tr '[:upper:]' '[:lower:]')
  if [[ "$confirm_db" == "y" ]]; then
    echo -e "\n📄 List of database backup files (.sql):"

    find "$SITE_DIR/backups" -type f -name "*.sql" | while read file; do
    file_time=$(stat -f "%Sm" -t "%d-%m-%Y %H:%M:%S" "$file")
    file_name=$(basename "$file")
    echo -e "$file_name\t$file_time"
    done | nl -s ". "

    [[ "$TEST_MODE" != true ]] && read -p "📝 Enter database backup filename or paste path: " DB_BACKUP_FILE

    # Check if filename has relative path, convert to absolute path
    if [[ ! "$DB_BACKUP_FILE" =~ ^/ ]]; then
        DB_BACKUP_FILE="$SITE_DIR/backups/$DB_BACKUP_FILE"
    fi

    # Check if file exists
    if [[ ! -f "$DB_BACKUP_FILE" ]]; then
        echo "❌ Database backup file does not exist: $DB_BACKUP_FILE"
        exit 1
    else
        echo "✅ Found backup file: $DB_BACKUP_FILE"
    fi

    export MYSQL_ROOT_PASSWORD=$(fetch_env_variable "$SITE_DIR/.env" "MYSQL_ROOT_PASSWORD")
    if [[ -z "$MYSQL_ROOT_PASSWORD" ]]; then
      echo -e "${RED}❌ Could not get MYSQL_ROOT_PASSWORD from .env${NC}"
      return 1
    fi

    backup_restore_database "$DB_BACKUP_FILE" "$DB_CONTAINER"
  fi

  echo -e "${GREEN}✅ Website '$SITE_NAME' restore completed.${NC}"
}
