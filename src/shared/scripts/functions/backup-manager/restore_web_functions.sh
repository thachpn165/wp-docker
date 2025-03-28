#!/bin/bash

# ===========================================
# Hàm khôi phục backup mã nguồn của website
# ===========================================

backup_restore_files() {
  BACKUP_FILE="$1"  # Đường dẫn đến file backup mã nguồn (tar.gz)
  SITE_DIR="$2"     # Thư mục chứa website cần khôi phục

  if [[ -z "$BACKUP_FILE" || -z "$SITE_DIR" ]]; then
    echo "❌ Thiếu tham số: Đường dẫn file backup hoặc thư mục website không hợp lệ!"
    return 1
  fi

  # Kiểm tra file backup có tồn tại không
  if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "❌ Không tìm thấy file backup: $BACKUP_FILE"
    return 1
  fi

  # Giải nén mã nguồn vào thư mục website
  echo "📦 Đang khôi phục mã nguồn từ $BACKUP_FILE vào $SITE_DIR/wordpress..."
  tar -xzf "$BACKUP_FILE" -C "$SITE_DIR/wordpress"
  
  if [[ $? -eq 0 ]]; then
    echo "✅ Mã nguồn đã được khôi phục thành công từ backup."
  else
    echo "❌ Đã xảy ra lỗi khi khôi phục mã nguồn từ backup."
    return 1
  fi
}

# ===========================================
# Hàm khôi phục backup cơ sở dữ liệu
# ===========================================

backup_restore_database() {
  DB_BACKUP="$1"          # Đường dẫn đến file backup cơ sở dữ liệu (.sql)
  DB_CONTAINER="$2"       # Tên container chứa cơ sở dữ liệu (mariadb)

  if [[ -z "$DB_BACKUP" || -z "$DB_CONTAINER" ]]; then
    echo "❌ Thiếu tham số: Đường dẫn file backup cơ sở dữ liệu hoặc container không hợp lệ!"
    return 1
  fi

  # Kiểm tra file backup cơ sở dữ liệu có tồn tại không
  if [[ ! -f "$DB_BACKUP" ]]; then
    echo "❌ Không tìm thấy file backup cơ sở dữ liệu: $DB_BACKUP"
    return 1
  fi

  # Khôi phục cơ sở dữ liệu từ file backup
  echo "🔄 Đang khôi phục cơ sở dữ liệu từ $DB_BACKUP vào container $DB_CONTAINER..."
  docker exec -i "$DB_CONTAINER" mysql -u root -p"$MYSQL_ROOT_PASSWORD" < "$DB_BACKUP"
  
  if [[ $? -eq 0 ]]; then
    echo "✅ Cơ sở dữ liệu đã được khôi phục thành công từ backup."
  else
    echo "❌ Đã xảy ra lỗi khi khôi phục cơ sở dữ liệu từ backup."
    return 1
  fi
}

