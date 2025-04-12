# =============================================
# 🌐 lang_loader – Load language file từ .config.json
# =============================================

# ✅ Prevent multiple loading of language files
[[ -n "$LANG_LOADED" ]] && return
LANG_LOADED=true

if [[ -z "$PROJECT_DIR" ]]; then
  SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]:-$0}")"
  while [[ "$SCRIPT_PATH" != "/" ]]; do
    if [[ -f "$SCRIPT_PATH/shared/config/config.sh" ]]; then
      safe_source "$SCRIPT_PATH/shared/config/config.sh"
      break
    fi
    SCRIPT_PATH="$(dirname "$SCRIPT_PATH")"
  done
fi

# === Đọc mã ngôn ngữ từ .config.json
lang_code="$(json_get_value '.core.lang')"

# === Kiểm tra tồn tại file tương ứng
LANG_FILE="$BASE_DIR/shared/lang/${lang_code}.sh"
if [[ -f "$LANG_FILE" ]]; then
  safe_source "$LANG_FILE"
else
  echo "⚠️ Language file not found for '$lang_code': $LANG_FILE. Falling back to Vietnamese."
  safe_source "$BASE_DIR/shared/lang/vi.sh"
fi