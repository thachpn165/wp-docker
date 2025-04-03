#!/bin/bash

# === Load config & website_loader.sh ===
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
  echo "${CROSSMARK} Config file not found at: $CONFIG_FILE" >&2
  exit 1
fi
source "$CONFIG_FILE"
source "$FUNCTIONS_DIR/backup_loader.sh"

# === Select website ===
select_website

# Ensure site is selected
if [[ -z "$SITE_NAME" ]]; then
    echo "${CROSSMARK} No website selected. Exiting."
    exit 1
fi

#echo "Selected site: $SITE_NAME"

# === Ask for restoring source code ===
read -p "📦 Do you want to restore SOURCE CODE? [y/N]: " confirm_code
confirm_code=$(echo "$confirm_code" | tr '[:upper:]' '[:lower:]')

if [[ "$confirm_code" == "y" ]]; then
    echo -e "\n📄 List of source code backup files (.tar.gz):"
    
    # List the source code backup files
    find "$SITES_DIR/$SITE_NAME/backups" -type f -name "*.tar.gz" | while read file; do
        file_time=$(stat -f "%Sm" -t "%d-%m-%Y %H:%M:%S" "$file")
        file_name=$(basename "$file")
        echo -e "$file_name\t$file_time"
    done | nl -s ". "
    
    read -p "📝 Enter source code backup filename or paste path: " code_backup_file
    
    # Handle relative paths
    if [[ ! "$code_backup_file" =~ ^/ ]]; then
        code_backup_file="$SITES_DIR/$SITE_NAME/backups/$code_backup_file"
    fi

    # Check if the file exists
    if [[ ! -f "$code_backup_file" ]]; then
        echo "${CROSSMARK} Source code backup file does not exist: $code_backup_file"
        exit 1
    else
        echo "${CHECKMARK} Found backup file: $code_backup_file"
    fi
else
    code_backup_file=""
    echo "Skipping source code restore."
fi

# === Ask for restoring database ===
read -p "🛢  Do you want to restore DATABASE? [y/N]: " confirm_db
confirm_db=$(echo "$confirm_db" | tr '[:upper:]' '[:lower:]')

if [[ "$confirm_db" == "y" ]]; then
    echo -e "\n📄 List of database backup files (.sql):"
    
    # List the database backup files
    find "$SITES_DIR/$SITE_NAME/backups" -type f -name "*.sql" | while read file; do
        file_time=$(stat -f "%Sm" -t "%d-%m-%Y %H:%M:%S" "$file")
        file_name=$(basename "$file")
        echo -e "$file_name\t$file_time"
    done | nl -s ". "
    
    read -p "📝 Enter database backup filename or paste path: " db_backup_file
    
    # Handle relative paths
    if [[ ! "$db_backup_file" =~ ^/ ]]; then
        db_backup_file="$SITES_DIR/$SITE_NAME/backups/$db_backup_file"
    fi

    # Check if the file exists
    if [[ ! -f "$db_backup_file" ]]; then
        echo "${CROSSMARK} Database backup file does not exist: $db_backup_file"
        exit 1
    else
        echo "${CHECKMARK} Found backup file: $db_backup_file"
    fi

    # Fetch MYSQL_ROOT_PASSWORD from .env
    mysql_root_password=$(fetch_env_variable "$SITES_DIR/$SITE_NAME/.env" "MYSQL_ROOT_PASSWORD")
    if [[ -z "$mysql_root_password" ]]; then
        echo -e "${RED}${CROSSMARK} Could not get MYSQL_ROOT_PASSWORD from .env${NC}"
        exit 1
    fi
else
    db_backup_file=""
    echo "Skipping database restore."
fi

# === Call the restore logic via CLI ===
bash "$CLI_DIR/backup_restore_web.sh" --site_name="$SITE_NAME" --code_backup_file="$code_backup_file" --db_backup_file="$db_backup_file"