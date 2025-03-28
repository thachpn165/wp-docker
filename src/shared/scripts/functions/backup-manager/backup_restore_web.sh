#!/bin/bash

# =====================================
# 🔄 Khôi phục website từ backup (mã nguồn + database)
# =====================================

source "$SCRIPTS_FUNCTIONS_DIR/backup-manager/backup_restore_functions.sh"

backup_restore_web() {
  echo -e "${BLUE}===== KHÔI PHỤC WEBSITE Từ BACKUP =====${NC}"

  # ✅ Chọn website
  select_website || return 1
  echo "DEBUG: SITE_NAME=$SITE_NAME"  # Debugging line
  SITE_DIR="$SITES_DIR/$SITE_NAME"
  DB_CONTAINER="${SITE_NAME}-mariadb"

  if ! is_directory_exist "$SITE_DIR"; then
    echo -e "${RED}❌ Thư mục website không tồn tại: $SITE_DIR${NC}"
    return 1
  fi

  # ========== ♻ Restore Mã nguồn ==========
  read -p "📦 Bạn có muốn khôi phục MÃ NGUỒN không? [y/N]: " confirm_code
  confirm_code=$(echo "$confirm_code" | tr '[:upper:]' '[:lower:]')
  if [[ "$confirm_code" == "y" ]]; then
    echo -e "\n📄 Danh sách file backup mã nguồn (.tar.gz):"

    find "$SITE_DIR/backups" -type f -name "*.tar.gz" | while read file; do
    file_time=$(stat -f "%Sm" -t "%d-%m-%Y %H:%M:%S" "$file")
    file_name=$(basename "$file")
    echo -e "$file_name\t$file_time"
    done | nl -s ". "

    read -p "📝 Nhập tên file backup mã nguồn hoặc dán đường dẫn: " CODE_BACKUP_FILE

    # Kiểm tra nếu tên file có đường dẫn tương đối, và chuyển thành đường dẫn tuyệt đối
    if [[ ! "$CODE_BACKUP_FILE" =~ ^/ ]]; then
        CODE_BACKUP_FILE="$SITE_DIR/backups/$CODE_BACKUP_FILE"
    fi

    # Kiểm tra xem file có tồn tại không
    if [[ ! -f "$CODE_BACKUP_FILE" ]]; then
        echo "❌ File backup mã nguồn không tồn tại: $CODE_BACKUP_FILE"
        exit 1
    else
        echo "✅ Đã tìm thấy file backup: $CODE_BACKUP_FILE"
    fi

    backup_restore_files "$CODE_BACKUP_FILE" "$SITE_DIR"
  fi

  # ========== 🔄 Restore Database ==========
  read -p "🛢  Bạn có muốn khôi phục DATABASE không? [y/N]: " confirm_db
  confirm_db=$(echo "$confirm_db" | tr '[:upper:]' '[:lower:]')
  if [[ "$confirm_db" == "y" ]]; then
    echo -e "\n📄 Danh sách file backup database (.sql):"

    find "$SITE_DIR/backups" -type f -name "*.sql" | while read file; do
    file_time=$(stat -f "%Sm" -t "%d-%m-%Y %H:%M:%S" "$file")
    file_name=$(basename "$file")
    echo -e "$file_name\t$file_time"
    done | nl -s ". "

    read -p "📝 Nhập tên file backup database hoặc dán đường dẫn: " DB_BACKUP_FILE

    # Kiểm tra nếu tên file có đường dẫn tương đối, và chuyển thành đường dẫn tuyệt đối
    if [[ ! "$DB_BACKUP_FILE" =~ ^/ ]]; then
        DB_BACKUP_FILE="$SITE_DIR/backups/$DB_BACKUP_FILE"
    fi

    # Kiểm tra xem file có tồn tại không
    if [[ ! -f "$DB_BACKUP_FILE" ]]; then
        echo "❌ File backup database không tồn tại: $DB_BACKUP_FILE"
        exit 1
    else
        echo "✅ Đã tìm thấy file backup: $DB_BACKUP_FILE"
    fi

    export MYSQL_ROOT_PASSWORD=$(fetch_env_variable "$SITE_DIR/.env" "MYSQL_ROOT_PASSWORD")
    if [[ -z "$MYSQL_ROOT_PASSWORD" ]]; then
      echo -e "${RED}❌ Không lấy được MYSQL_ROOT_PASSWORD từ .env${NC}"
      return 1
    fi

    backup_restore_database "$DB_BACKUP_FILE" "$DB_CONTAINER"
  fi

  echo -e "${GREEN}✅ Hoàn tất khôi phục website '$SITE_NAME'.${NC}"
}
