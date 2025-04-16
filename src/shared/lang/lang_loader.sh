# =============================================
# 🌐 lang_loader – Load language file from .config.json
# =============================================

# ✅ Prevent multiple loading
[[ -n "$LANG_LOADED" ]] && return
LANG_LOADED=true

# === Auto-detect PROJECT_DIR if not set ===
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

# === Read language code from .config.json
lang_code="$(json_get_value '.core.lang')"

# === Fallback to 'vi' if not found
LANG_FILE="$BASE_DIR/shared/lang/${lang_code}.sh"
if [[ -f "$LANG_FILE" ]]; then
  safe_source "$LANG_FILE"
else
  echo -e "⚠️  Language file not found for '${lang_code}' → Using English fallback"
  safe_source "$BASE_DIR/shared/lang/en.sh"
fi