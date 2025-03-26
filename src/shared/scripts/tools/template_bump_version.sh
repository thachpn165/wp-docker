#!/bin/bash

# =========================================
# 🛠 template_bump_version.sh
# Tăng phiên bản template & ghi changelog
# Hỗ trợ chạy tay (dev) và tự động (CI/CD)
# =========================================

TEMPLATE_DIR="shared/templates"
VERSION_FILE="$TEMPLATE_DIR/.template_version"
CHANGELOG_FILE="$TEMPLATE_DIR/TEMPLATE_CHANGELOG.md"

# ✅ Đảm bảo file tồn tại
mkdir -p "$TEMPLATE_DIR"
touch "$VERSION_FILE"
touch "$CHANGELOG_FILE"

# 🧠 Hàm tính version tiếp theo
bump_version() {
  local ver="$1"
  echo "$ver" | awk -F. '{$NF+=1; OFS="."; print}'
}

# ========================================
# 🤖 CHẾ ĐỘ TỰ ĐỘNG (từ GitHub Actions)
# ========================================
if [[ "$1" == "--auto" ]]; then
  CUR_VER=$(cat "$VERSION_FILE" 2>/dev/null || echo "0.0.0")
  NEXT_VER=$(bump_version "$CUR_VER")
  DATE_NOW=$(date '+%Y-%m-%d %H:%M:%S')

  echo "$NEXT_VER" > "$VERSION_FILE"

  echo "" >> "$CHANGELOG_FILE"
  echo "## $NEXT_VER – $DATE_NOW" >> "$CHANGELOG_FILE"
  echo "- 🤖 Tự động bump từ GitHub Actions" >> "$CHANGELOG_FILE"

  echo "✅ Auto bump template version: $CUR_VER → $NEXT_VER"
  exit 0
fi

# ========================================
# 🧑 Chế độ thủ công (developer)
# ========================================
CUR_VER=$(cat "$VERSION_FILE" 2>/dev/null || echo "0.0.0")
echo "🔢 Template version hiện tại: $CUR_VER"

read -rp "👉 Nhập version mới (VD: 1.0.7): " NEW_VER
[[ -z "$NEW_VER" ]] && echo "❌ Bạn chưa nhập version mới!" && exit 1
[[ "$NEW_VER" == "$CUR_VER" ]] && echo "⚠️ Phiên bản mới giống phiên bản hiện tại." && exit 0

read -rp "📝 Mô tả changelog cho bản $NEW_VER: " CHANGELOG_LINE
DATE_NOW=$(date '+%Y-%m-%d %H:%M:%S')

# ✅ Ghi version & changelog
echo "$NEW_VER" > "$VERSION_FILE"

{
  echo ""
  echo "## $NEW_VER – $DATE_NOW"
  echo "- $CHANGELOG_LINE"
} >> "$CHANGELOG_FILE"

echo "✅ Đã cập nhật .template_version → $NEW_VER"
echo "📄 Đã ghi vào TEMPLATE_CHANGELOG.md"
