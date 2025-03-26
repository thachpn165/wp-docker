#!/bin/bash

# =========================================
# 🛠 template_bump_version.sh
# Tăng phiên bản template & ghi changelog
# Hỗ trợ chạy tay và CI/CD
# =========================================

# === 🔍 Tìm và load config.sh ===
if [[ -n "$PROJECT_DIR" ]]; then
  CONFIG_FILE="$PROJECT_DIR/shared/config/config.sh"
else
  # Xác định thư mục chứa script hiện tại (an toàn cho mọi trường hợp)
  SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
  SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
  CONFIG_FILE="$SCRIPT_DIR/../../config/config.sh"
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Không tìm thấy config.sh tại: $CONFIG_FILE" >&2
  exit 1
fi

source "$CONFIG_FILE"

# ✅ Đảm bảo file tồn tại
mkdir -p "$TEMPLATE_DIR"
touch "$TEMPLATE_VERSION_FILE"
touch "$TEMPLATE_CHANGELOG_FILE"

# 🧠 Hàm tính version tiếp theo
bump_version() {
  local ver="$1"
  IFS='.' read -r major minor patch <<< "$ver"

  major=${major:-1}
  minor=${minor:-0}
  patch=${patch:-0}
  patch=$((patch + 1))

  echo "$major.$minor.$patch"
}

# ========================================
# 🤖 CHẾ ĐỘ TỰ ĐỘNG (CI/CD)
# ========================================
if [[ "$1" == "--auto" ]]; then
  if [[ -f "$TEMPLATE_VERSION_FILE" && -s "$TEMPLATE_VERSION_FILE" ]]; then
    CUR_VER=$(<"$TEMPLATE_VERSION_FILE")
  else
    CUR_VER="1.0.0"
  fi

  NEXT_VER=$(bump_version "$CUR_VER")
  DATE_NOW=$(date '+%Y-%m-%d %H:%M:%S')

  echo ">>> BEFORE: $(cat "$TEMPLATE_VERSION_FILE")"
  echo "$NEXT_VER" > "$TEMPLATE_VERSION_FILE"
  sync  # Ensure file is written

  echo ">>> AFTER: $(cat "$TEMPLATE_VERSION_FILE")"

  {
    echo ""
    echo "## $NEXT_VER – $DATE_NOW"
    echo "- 🤖 Auto bump version from CI"
  } >> "$TEMPLATE_CHANGELOG_FILE"

  echo "✅ Auto bump template version: $CUR_VER → $NEXT_VER"
  exit 0
fi

# ========================================
# 👨‍💻 Chế độ thủ công (dev)
# ========================================
CUR_VER=$(cat "$TEMPLATE_VERSION_FILE" 2>/dev/null || echo "0.0.0")
echo "🔢 Current template version: $CUR_VER"

read -rp "👉 Enter new version (e.g. 1.0.7): " NEW_VER
[[ -z "$NEW_VER" ]] && echo "❌ No version entered!" && exit 1
[[ "$NEW_VER" == "$CUR_VER" ]] && echo "⚠️ Version unchanged." && exit 0

read -rp "📝 Enter changelog message: " CHANGELOG_LINE
DATE_NOW=$(date '+%Y-%m-%d %H:%M:%S')

echo "$NEW_VER" > "$TEMPLATE_VERSION_FILE"
sync  # Ensure file is written

{
  echo ""
  echo "## $NEW_VER – $DATE_NOW"
  echo "- $CHANGELOG_LINE"
} >> "$TEMPLATE_CHANGELOG_FILE"

echo "✅ Updated template version to: $NEW_VER"
echo "📄 Changelog updated at: $TEMPLATE_CHANGELOG_FILE"
