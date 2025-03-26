# Hiển thị danh sách website để chọn
select_website() {
    local sites=($(ls -d $SITES_DIR/*/ | xargs -n 1 basename))
    if [[ ${#sites[@]} -eq 0 ]]; then
        echo -e "${RED}❌ Không tìm thấy website nào trong $SITES_DIR${NC}"
        return 1
    fi

    echo -e "${BLUE}🔹 Chọn một website:${NC}"
    echo ""
    select SITE_NAME in "${sites[@]}"; do
        if [[ -n "$SITE_NAME" ]]; then
            echo -e "${GREEN}✅ Đã chọn: $SITE_NAME${NC}"
            break
        else
            echo -e "${RED}❌ Lựa chọn không hợp lệ!${NC}"
        fi
    done
}

# 🔍 Quét danh sách site từ thư mục sites
get_site_list() {
  find "$SITES_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
}

# =====================================
# ♻️ website_restore_from_archive – Khôi phục website từ thư mục archive
# =====================================

website_restore_from_archive() {
  ARCHIVE_DIR="$BASE_DIR/archives/old_website"

  if [[ ! -d "$ARCHIVE_DIR" ]]; then
    echo -e "${RED}❌ Không tìm thấy thư mục lưu trữ: $ARCHIVE_DIR${NC}"
    return 1
  fi

  echo -e "${YELLOW}📦 Danh sách website đã lưu trữ:${NC}"
  archive_list=( $(ls -1 "$ARCHIVE_DIR") )

  if [ ${#archive_list[@]} -eq 0 ]; then
    echo -e "${RED}❌ Không có website nào để khôi phục.${NC}"
    return 1
  fi

  for i in "${!archive_list[@]}"; do
    echo -e "  ${GREEN}[$i]${NC} ${archive_list[$i]}"
  done

  echo ""
  read -p "Chọn site cần khôi phục (số): " archive_index
  selected_folder="${archive_list[$archive_index]}"
  archive_path="$ARCHIVE_DIR/$selected_folder"

  site_name=$(echo "$selected_folder" | cut -d '-' -f1)
  restore_target="$SITES_DIR/$site_name"

  if [[ -d "$restore_target" ]]; then
    echo -e "${RED}❌ Thư mục $restore_target đã tồn tại. Không thể ghi đè.${NC}"
    return 1
  fi

  mkdir -p "$restore_target/wordpress" "$restore_target/logs" "$restore_target/backups" "$restore_target/php" "$restore_target/mariadb"

  echo -e "${YELLOW}📂 Đang giải nén mã nguồn WordPress...${NC}"
  tar -xzf "$archive_path/${site_name}_wordpress.tar.gz" -C "$restore_target/wordpress"

  echo -e "${YELLOW}🛠️ Đang khôi phục database...${NC}"
  cp "$archive_path/${site_name}_db.sql" "$restore_target/backups/${site_name}_db.sql"

  echo -e "${GREEN}✅ Khôi phục mã nguồn và database thành công.${NC}"
  echo -e "${YELLOW}👉 Hãy tạo lại file .env và cấu hình docker-compose để chạy lại site.${NC}"

  read -p "Bạn có muốn mở thư mục site mới khôi phục không? (y/N): " open_choice
  if [[ "$open_choice" =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}📁 Đường dẫn: $restore_target${NC}"
    ls -al "$restore_target"
  fi
}